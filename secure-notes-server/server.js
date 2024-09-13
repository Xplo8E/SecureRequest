const express = require('express');
const dotenv = require('dotenv');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const CryptoJS = require('crypto-js');
const { body, validationResult } = require('express-validator');
const winston = require('winston');
const crypto = require('crypto');

dotenv.config();

// Set up winston logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.printf(({ timestamp, level, message }) => {
      return `${timestamp} ${level}: ${message}`;
    })
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'server.log' })
  ]
});

const app = express();
app.use(express.json());

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// AES encryption key (should be stored securely, not in the code)
const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY;

// Flag to toggle IDOR vulnerability (for demonstration purposes only)
const ALLOW_IDOR = process.env.ALLOW_IDOR === 'true';

// Middleware for decrypting request bodies
const decryptBody = (req, res, next) => {
  if (req.body.data) {
    try {
    //   console.log("Received encrypted data:", req.body.data);
      const encryptedData = Buffer.from(req.body.data, 'base64');
      const key = Buffer.from(ENCRYPTION_KEY, 'utf8');
      const iv = encryptedData.slice(0, 12);
      const tag = encryptedData.slice(-16);
      const ciphertext = encryptedData.slice(12, -16);
      
    //   console.log("Key:", key);
    //   console.log("IV:", iv);
    //   console.log("Tag:", tag);
    //   console.log("Ciphertext:", ciphertext);
      
      const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
      decipher.setAuthTag(tag);
      let decrypted = decipher.update(ciphertext, null, 'utf8');
      decrypted += decipher.final('utf8');
    //   console.log("Decrypted string:", decrypted);
      const decryptedData = JSON.parse(decrypted);
      logger.info(`[+] Encrypted data received: ${req.body.data}`);
      logger.info(`[+] Decrypted data: ${JSON.stringify(decryptedData)}`);
      req.body = decryptedData;
    } catch (error) {
      logger.error(`Error decrypting request body: ${error.message}`);
      return res.status(400).json({ error: 'Invalid encrypted data' });
    }
  }
  next();
};

// Middleware for encrypting response bodies
const encryptResponse = (req, res, next) => {
  const originalJson = res.json;
  res.json = function (body) {
    const key = Buffer.from(ENCRYPTION_KEY, 'utf8');
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
    let encrypted = cipher.update(JSON.stringify(body), 'utf8', 'base64');
    encrypted += cipher.final('base64');
    const tag = cipher.getAuthTag();
    const encryptedData = Buffer.concat([iv, Buffer.from(encrypted, 'base64'), tag]).toString('base64');
    originalJson.call(this, { data: encryptedData });
    logger.info(`Response body before encryption: ${JSON.stringify(body)}`);
    logger.info(`[+] Encrypted response data: ${encryptedData}`);
  };
  next();
};

// Apply encryption middleware to all routes
app.use(decryptBody);
app.use(encryptResponse);

// Middleware for token verification
const verifyToken = (req, res, next) => {
  const token = req.headers['authorization'];
  if (!token) {
    logger.warn(`[!] No token provided`);
    return res.status(403).json({ error: 'No token provided' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      logger.error(`[!] Failed to authenticate token: ${err}`);
      return res.status(500).json({ error: 'Failed to authenticate token' });
    }
    logger.info(`[+] Token verified successfully. User ID: ${decoded.id}`);
    req.userId = decoded.id;
    next();
  });
};

// Validation middleware
const validate = (validations) => {
  return async (req, res, next) => {
    await Promise.all(validations.map(validation => validation.run(req)));

    const errors = validationResult(req);
    if (errors.isEmpty()) {
      return next();
    }

    res.status(400).json({ errors: errors.array() });
  };
};

// User Registration
app.post('/api/register', validate([
  body('username').isLength({ min: 3 }).trim().escape(),
  body('password').isLength({ min: 6 })
]), async (req, res) => {
  try {
    const { username, password } = req.body;
    logger.info(`Registering user: ${username}`);
    const hashedPassword = await bcrypt.hash(password, 10);
    const result = await pool.query(
      'INSERT INTO users (username, password_hash) VALUES ($1, $2) RETURNING id',
      [username, hashedPassword]
    );
    res.status(201).json({ message: 'User registered successfully' });
  } catch (error) {
    logger.error(`Error registering user: ${error.message}`);
    res.status(500).json({ error: 'Error registering user' });
  }
});

// User Login
app.post('/api/login', validate([
  body('username').isLength({ min: 3 }).trim().escape(),
  body('password').isLength({ min: 6 })
]), async (req, res) => {
  try {
    const { username, password } = req.body;
    const result = await pool.query('SELECT * FROM users WHERE username = $1', [username]);
    if (result.rows.length === 0) return res.status(401).json({ error: 'Invalid credentials' });

    const user = result.rows[0];
    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.json({ token });
  } catch (error) {
    res.status(500).json({ error: 'Error logging in' });
  }
});

app.post('/api/notes', verifyToken, async (req, res) => {
  try {
    const { title, content } = req.body;
    const userId = req.userId;
  
    const result = await pool.query(
      'INSERT INTO notes (user_id, title, content) VALUES ($1, $2, $3) RETURNING *',
      [userId, title, content]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error adding note:', error);
    res.status(500).json({ error: 'Error adding note' });
  }
});

// Fetch Personal Notes
app.get('/api/notes', verifyToken, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM notes WHERE user_id = $1', [req.userId]);
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching notes:', error);
    res.status(500).json({ error: 'Error fetching notes' });
  }
});

// Update a note
app.put('/api/notes/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { title, content } = req.body;
    const userId = req.userId;

    // First, check if the note exists
    const noteExistsResult = await pool.query('SELECT user_id FROM notes WHERE id = $1', [id]);
    
    if (noteExistsResult.rows.length === 0) {
      return res.status(404).json({ error: 'Note not found' });
    }
    
    if (!ALLOW_IDOR) {
      // SECURE VERSION: Check if the note belongs to the current user
      if (noteExistsResult.rows[0].user_id !== userId) {
        logger.warn(`Access denied: User ${userId} attempted to update note ${id}`);
        return res.status(403).json({ error: 'Access denied' });
      }
    } else {
      logger.warn('IDOR vulnerability active. Skipping user check for update.');
    }

    // If we've made it here, either IDOR is allowed or the note belongs to the user
    const result = await pool.query(
      'UPDATE notes SET title = $1, content = $2, updated_at = CURRENT_TIMESTAMP WHERE id = $3 RETURNING *',
      [title, content, id]
    );

    res.json({ message: 'Note updated successfully', note: result.rows[0] });
  } catch (error) {
    logger.error(`Error updating note: ${error.message}`);
    res.status(500).json({ error: 'Error updating note' });
  }
});

// Delete a note
app.delete('/api/notes/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    // First, check if the note exists
    const noteExistsResult = await pool.query('SELECT user_id FROM notes WHERE id = $1', [id]);
    
    if (noteExistsResult.rows.length === 0) {
      return res.status(404).json({ error: 'Note not found' });
    }
    
    if (!ALLOW_IDOR) {
      // SECURE VERSION: Check if the note belongs to the current user
      if (noteExistsResult.rows[0].user_id !== userId) {
        logger.warn(`Access denied: User ${userId} attempted to delete note ${id}`);
        return res.status(403).json({ error: 'Access denied' });
      }
    } else {
      logger.warn('IDOR vulnerability active. Skipping user check for delete.');
    }

    // If we've made it here, either IDOR is allowed or the note belongs to the user
    const result = await pool.query('DELETE FROM notes WHERE id = $1 RETURNING *', [id]);

    res.json({ message: 'Note deleted successfully', note: result.rows[0] });
  } catch (error) {
    logger.error(`Error deleting note: ${error.message}`);
    res.status(500).json({ error: 'Error deleting note' });
  }
});

// Fetch a single note by ID
app.get('/api/notes/:id', verifyToken, async (req, res) => {
  try {
    const noteId = req.params.id;

    // First, check if the note exists
    const noteExistsResult = await pool.query('SELECT user_id FROM notes WHERE id = $1', [noteId]);
    
    if (noteExistsResult.rows.length === 0) {
      return res.status(404).json({ error: 'Note not found' });
    }
    
    if (!ALLOW_IDOR) {
      // SECURE VERSION: Check if the note belongs to the current user
      if (noteExistsResult.rows[0].user_id !== req.userId) {
        logger.warn(`Access denied: User ${req.userId} attempted to access note ${noteId}`);
        return res.status(403).json({ error: 'Access denied' });
      }
    } else {
      logger.warn('IDOR vulnerability active. Skipping user check.');
    }
    
    // If we've made it here, either IDOR is allowed or the note belongs to the user
    const result = await pool.query('SELECT * FROM notes WHERE id = $1', [noteId]);
    res.json(result.rows[0]);
  } catch (error) {
    logger.error(`Error fetching note: ${error.message}`);
    res.status(500).json({ error: 'Error fetching note' });
  }
});

let VICTIM_TOKEN;
let ATTACKER_TOKEN;

// Function to create sample data and generate tokens
async function createSampleData() {
  try {
    // Clear existing data
    await pool.query('TRUNCATE users, notes RESTART IDENTITY CASCADE');

    // Create users
    const usersResult = await pool.query(
      'INSERT INTO users (username, password_hash) VALUES ($1, $2), ($3, $4) RETURNING id', 
      ['victim', 'victim_hash', 'attacker', 'attacker_hash']
    );
    const victimId = usersResult.rows[0].id;
    const attackerId = usersResult.rows[1].id;

    // Generate tokens
    VICTIM_TOKEN = jwt.sign({ id: victimId }, process.env.JWT_SECRET);
    ATTACKER_TOKEN = jwt.sign({ id: attackerId }, process.env.JWT_SECRET);

    // Create notes for victim
    await pool.query(
      'INSERT INTO notes (user_id, title, content) VALUES ($1, $2, $3), ($1, $4, $5)', 
      [victimId, 'Victim Secret 1', 'Secret info of victim 1', 'Victim Secret 2', 'Secret info of victim 2']
    );

    // Create notes for attacker
    await pool.query(
      'INSERT INTO notes (user_id, title, content) VALUES ($1, $2, $3)', 
      [attackerId, 'Attacker Note', 'This is attacker\'s note']
    );

    // Fetch and log the created data
    const users = await pool.query('SELECT * FROM users');
    const notes = await pool.query('SELECT * FROM notes');

    logger.info('Sample data created successfully:');
    logger.info('Users:');
    logger.info(JSON.stringify(users.rows, null, 2));
    logger.info('Notes:');
    logger.info(JSON.stringify(notes.rows, null, 2));
    logger.info('Victim Token: ' + VICTIM_TOKEN);
    logger.info('Attacker Token: ' + ATTACKER_TOKEN);

  } catch (error) {
    logger.error('Error creating sample data:', error);
  }
}

// Start the server and create sample data
const PORT = process.env.PORT || 3000;
app.listen(PORT, async () => {
  logger.info(`Server running on port ${PORT}`);
  await createSampleData();
});

// Test encryption route
app.post('/api/test-encryption', (req, res) => {
  const { data } = req.body;
  console.log("Received test data:", data);
  try {
    const encryptedData = Buffer.from(data, 'base64');
    const key = Buffer.from(ENCRYPTION_KEY, 'utf8');
    const iv = encryptedData.slice(0, 12);
    const tag = encryptedData.slice(-16);
    const ciphertext = encryptedData.slice(12, -16);
    
    // console.log("Key:", key);
    // console.log("IV:", iv);
    // console.log("Tag:", tag);
    // console.log("Ciphertext:", ciphertext);
    
    const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
    decipher.setAuthTag(tag);
    let decrypted = decipher.update(ciphertext, null, 'utf8');
    decrypted += decipher.final('utf8');
    console.log("Decrypted test data:", decrypted);
    res.json({ success: true, decrypted });
  } catch (error) {
    console.error("Test decryption error:", error);
    res.status(400).json({ error: error.message });
  }
});
