const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    this.transporter = null;
    this.fallbackTransporter = null;
    this.initialized = false;
    this.emailQueue = [];
    this.retryAttempts = 3;
    this.rateLimitWindow = 60000; // 1 minute
    this.emailsSentThisWindow = 0;
    this.windowStart = Date.now();
    this.maxEmailsPerWindow = 100; // Production rate limit
    
    // Environment detection
    this.isProduction = process.env.NODE_ENV === 'production';
    this.isDevelopment = process.env.NODE_ENV === 'development';
    
    // Email statistics
    this.stats = {
      sent: 0,
      failed: 0,
      queued: 0,
      lastSent: null,
      lastError: null
    };
  }

  // Initialize the email service with configuration
  async init() {
    try {
      // Validate environment variables
      if (!this.validateConfiguration()) {
        this.initialized = false;
        return;
      }

      // Initialize primary transporter
      await this.initializePrimaryTransporter();
      
      // Initialize fallback transporter
      await this.initializeFallbackTransporter();
      
      // Start background email processor
      this.startEmailProcessor();
      
      console.log('✅ Production email service initialized successfully');
      console.log(`📊 Environment: ${this.isProduction ? 'PRODUCTION' : 'DEVELOPMENT'}`);
      console.log(`📈 Rate limit: ${this.maxEmailsPerWindow} emails per minute`);
      
    } catch (error) {
      console.error('❌ Email service initialization failed:', error.message);
      this.initialized = false;
    }
  }

  // Validate configuration for production
  validateConfiguration() {
    const required = ['SMTP_USER', 'SMTP_PASS'];
    const missing = required.filter(key => !process.env[key]);
    
    if (missing.length > 0) {
      console.error('❌ Missing email configuration:', missing.join(', '));
      return false;
    }
    
    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(process.env.SMTP_USER)) {
      console.error('❌ Invalid SMTP_USER email format');
      return false;
    }
    
    return true;
  }

  // Initialize primary transporter with production settings
  async initializePrimaryTransporter() {
    this.transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
      },
      tls: {
        rejectUnauthorized: false,
        ciphers: 'SSLv3'
      },
      connectionTimeout: this.isProduction ? 30000 : 20000,
      greetingTimeout: this.isProduction ? 15000 : 10000,
      socketTimeout: this.isProduction ? 30000 : 20000,
      pool: true,
      maxConnections: this.isProduction ? 5 : 2,
      maxMessages: this.isProduction ? 100 : 10,
      logger: this.isDevelopment,
      debug: this.isDevelopment
    });

    // Verify primary transporter
    await this.verifyTransporter(this.transporter, 'Primary');
  }

  // Initialize fallback transporter
  async initializeFallbackTransporter() {
    this.fallbackTransporter = nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 587,
      secure: false,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
      },
      tls: {
        rejectUnauthorized: false,
        ciphers: 'SSLv3'
      },
      connectionTimeout: 15000,
      greetingTimeout: 8000,
      socketTimeout: 15000,
      pool: false,
      logger: false,
      debug: false
    });

    // Verify fallback transporter
    await this.verifyTransporter(this.fallbackTransporter, 'Fallback');
  }

  // Verify transporter with timeout
  async verifyTransporter(transporter, name) {
    if (process.env.SMTP_USER && process.env.SMTP_PASS) {
      try {
        // Set verification timeout
        const verificationPromise = transporter.verify();
        const timeoutPromise = new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Verification timeout')), 5000)
        );
        
        await Promise.race([verificationPromise, timeoutPromise]);
        console.log(`✅ ${name} email transporter verified successfully`);
        
        if (name === 'Primary') {
          this.initialized = true;
        }
      } catch (verifyError) {
        console.log(`⚠️ ${name} email verification failed:`, verifyError.message);
        if (name === 'Primary') {
          this.initialized = true; // Still try to send emails
        }
      }
    } else {
      console.log('⚠️ Email service not configured - SMTP credentials missing');
      this.initialized = false;
    }
  }

  // Start background email processor for production
  startEmailProcessor() {
    // Process queued emails every 30 seconds
    setInterval(() => {
      this.processEmailQueue();
    }, 30000);

    // Reset rate limit window every minute
    setInterval(() => {
      this.resetRateLimit();
    }, this.rateLimitWindow);
  }

  // Reset rate limiting counters
  resetRateLimit() {
    this.emailsSentThisWindow = 0;
    this.windowStart = Date.now();
  }

  // Check if rate limit is exceeded
  isRateLimited() {
    return this.emailsSentThisWindow >= this.maxEmailsPerWindow;
  }

  // Process queued emails
  async processEmailQueue() {
    if (this.emailQueue.length === 0 || this.isRateLimited()) {
      return;
    }

    const emailsToProcess = this.emailQueue.splice(0, Math.min(10, this.maxEmailsPerWindow - this.emailsSentThisWindow));
    
    for (const emailTask of emailsToProcess) {
      try {
        await this.processQueuedEmail(emailTask);
      } catch (error) {
        console.error('Failed to process queued email:', error.message);
      }
    }
  }

  // Process individual queued email
  async processQueuedEmail(emailTask) {
    const { type, mailOptions, retryCount = 0 } = emailTask;
    
    try {
      const result = await this.transporter.sendMail(mailOptions);
      this.stats.sent++;
      this.stats.lastSent = new Date();
      this.emailsSentThisWindow++;
      
      console.log(`✅ Queued ${type} email sent:`, {
        to: mailOptions.to,
        messageId: result.messageId
      });
      
    } catch (error) {
      console.error(`❌ Failed to send queued ${type} email:`, error.message);
      
      if (retryCount < this.retryAttempts) {
        // Retry with exponential backoff
        emailTask.retryCount = retryCount + 1;
        emailTask.nextRetry = Date.now() + (Math.pow(2, retryCount) * 60000); // Exponential backoff
        this.emailQueue.push(emailTask);
      } else {
        this.stats.failed++;
        this.stats.lastError = { error: error.message, timestamp: new Date() };
      }
    }
  }

  // Production email validation
  validateEmailRequest(userEmail, emailType) {
    // Check if service is initialized
    if (!this.initialized) {
      console.log('⚠️ Email service not initialized - skipping email');
      return { valid: false, success: false, reason: 'email_service_not_configured' };
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(userEmail)) {
      console.log('❌ Invalid email format:', userEmail);
      return { valid: false, success: false, reason: 'invalid_email_format' };
    }

    // Skip sending to test/example domains in production
    const testDomains = ['example.com', 'test.com', 'localhost', '10minutemail.com', 'guerrillamail.com'];
    const emailDomain = userEmail.split('@')[1]?.toLowerCase();
    
    if (this.isProduction && testDomains.includes(emailDomain)) {
      console.log(`⚠️ Skipping email to test domain in production: ${emailDomain}`);
      return { 
        valid: false,
        success: true, 
        reason: 'test_domain_skipped_production',
        message: `Email not sent to test domain in production: ${emailDomain}`
      };
    }

    // Development mode - allow test domains but warn
    if (!this.isProduction && testDomains.includes(emailDomain)) {
      console.log(`⚠️ Sending to test domain in development: ${emailDomain}`);
    }

    return { valid: true };
  }

  // Send email with comprehensive retry logic
  async sendEmailWithRetry(mailOptions, emailType, retryCount = 0) {
    try {
      return await this.transporter.sendMail(mailOptions);
    } catch (error) {
      console.error(`❌ Failed to send ${emailType} email (attempt ${retryCount + 1}):`, {
        error: error.message,
        code: error.code,
        to: mailOptions.to
      });

      // For timeout errors, try fallback strategies
      if ((error.code === 'ETIMEDOUT' || error.code === 'ECONNRESET') && retryCount < this.retryAttempts) {
        console.log(`🔄 Attempting ${emailType} email retry ${retryCount + 1}/${this.retryAttempts}...`);
        
        try {
          // Wait with exponential backoff
          await new Promise(resolve => setTimeout(resolve, Math.pow(2, retryCount) * 1000));
          
          // Try fallback transporter first
          if (this.fallbackTransporter && retryCount === 0) {
            console.log('🔄 Using fallback transporter...');
            return await this.fallbackTransporter.sendMail(mailOptions);
          }
          
          // Reinitialize primary transporter
          if (this.transporter && this.transporter.close) {
            await this.transporter.close();
          }
          await this.initializePrimaryTransporter();
          
          // Recursive retry
          return await this.sendEmailWithRetry(mailOptions, emailType, retryCount + 1);
          
        } catch (retryError) {
          console.error(`❌ Retry ${retryCount + 1} also failed:`, retryError.message);
          
          if (retryCount >= this.retryAttempts - 1) {
            // Final fallback: queue for manual processing
            this.stats.failed++;
            this.stats.lastError = { error: retryError.message, timestamp: new Date() };
            
            await this.queueEmailForManualSending({
              type: emailType,
              to: mailOptions.to,
              data: { mailOptions },
              timestamp: new Date().toISOString()
            });
            
            throw new Error(`All retry attempts failed: ${retryError.message}`);
          }
        }
      } else {
        // Non-timeout error or max retries reached
        this.stats.failed++;
        this.stats.lastError = { error: error.message, timestamp: new Date() };
        throw error;
      }
    }
  }

  // Queue email for later processing
  queueEmail(type, userEmail, data, options = {}) {
    const { name, password, credits, clientSource = 'Unknown' } = data || {};
    
    let mailOptions;
    let subject;
    
    if (type === 'welcome') {
      const welcomeTemplate = this.getWelcomeTemplate(name, userEmail, password, credits, clientSource);
      mailOptions = {
        from: {
          name: process.env.EMAIL_FROM_NAME || 'CloneX App',
          address: process.env.SMTP_USER
        },
        to: userEmail,
        subject: 'Welcome to CloneX - Your Account is Ready!',
        html: welcomeTemplate,
        text: this.getWelcomeTextVersion(name, userEmail, password, credits)
      };
      subject = 'Welcome Email';
    } else if (type === 'existing_user_credit') {
      const { credits, amount, clientSource = 'Unknown' } = data;
      const existingUserTemplate = this.getExistingUserTemplate(userEmail, credits, amount, clientSource);
      mailOptions = {
        from: {
          name: process.env.EMAIL_FROM_NAME || 'CloneX App',
          address: process.env.SMTP_USER
        },
        to: userEmail,
        subject: 'Credits Added to Your CloneX Account!',
        html: existingUserTemplate,
        text: this.getExistingUserTextVersion(userEmail, credits, amount)
      };
      subject = 'Credit Notification';
    }

    const emailTask = {
      type,
      mailOptions,
      queuedAt: new Date(),
      priority: options.priority || 'normal'
    };

    this.emailQueue.push(emailTask);
    this.stats.queued++;

    console.log(`📬 Email queued due to rate limiting: ${subject} for ${userEmail}`);
    
    return {
      success: true,
      queued: true,
      reason: 'rate_limited',
      message: `${subject} queued for delivery`,
      queuePosition: this.emailQueue.length
    };
  }

  // Get email service statistics
  getStats() {
    return {
      ...this.stats,
      queueLength: this.emailQueue.length,
      rateLimitStatus: {
        emailsSentThisWindow: this.emailsSentThisWindow,
        maxPerWindow: this.maxEmailsPerWindow,
        windowStart: new Date(this.windowStart),
        isLimited: this.isRateLimited()
      },
      transporter: {
        primary: this.transporter ? 'initialized' : 'not_initialized',
        fallback: this.fallbackTransporter ? 'initialized' : 'not_initialized'
      }
    };
  }

  // Method to reinitialize transporter (for retry scenarios)
  // Create fallback transporter without Gmail service dependency
  createFallbackTransporter() {
    return nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 587,
      secure: false,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
      },
      tls: {
        rejectUnauthorized: false,
        ciphers: 'SSLv3'
      },
      connectionTimeout: 15000, // Shorter timeout
      greetingTimeout: 8000,
      socketTimeout: 15000,
      pool: false, // No pooling for fallback
      logger: false,
      debug: false
    });
  }

  initializeTransporter() {
    // Primary: Gmail service
    this.transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
      },
      tls: {
        rejectUnauthorized: false,
        ciphers: 'SSLv3'
      },
      connectionTimeout: 20000, // 20 seconds
      greetingTimeout: 10000,   // 10 seconds
      socketTimeout: 20000,     // 20 seconds
      pool: true,
      maxConnections: 2,
      maxMessages: 10,
      logger: false,
      debug: false
    });
  }

  // Queue email for manual sending or alternative delivery
  async queueEmailForManualSending(emailData) {
    try {
      // You can store this in database or send to external service
      console.log('📬 Queuing email for alternative delivery:', {
        type: emailData.type,
        to: emailData.to,
        timestamp: emailData.timestamp
      });
      
      // For now, just log it - you can implement database storage later
      return { queued: true };
    } catch (error) {
      console.error('Failed to queue email:', error.message);
      return { queued: false };
    }
  }

  // Check if email service is healthy
  async checkConnection() {
    try {
      if (!this.transporter) {
        throw new Error('Transporter not initialized');
      }
      
      const verification = await this.transporter.verify();
      console.log('✅ Email connection healthy');
      return { healthy: true, message: 'Connection verified' };
    } catch (error) {
      console.log('❌ Email connection unhealthy:', error.message);
      return { healthy: false, error: error.message };
    }
  }

  // Send welcome email to new users with production features
  async sendWelcomeEmail(userEmail, userCredentials, clientInfo = {}) {
    // Production validation
    const validationResult = this.validateEmailRequest(userEmail, 'welcome');
    if (!validationResult.valid) {
      return validationResult;
    }

    // Rate limiting check
    if (this.isRateLimited()) {
      return this.queueEmail('welcome', userEmail, userCredentials, clientInfo);
    }

    const { name, password, credits, clientSource = 'Unknown' } = userCredentials;

    const welcomeTemplate = this.getWelcomeTemplate(
      name,
      userEmail,
      password,
      credits,
      clientSource
    );

    const mailOptions = {
      from: {
        name: process.env.EMAIL_FROM_NAME || 'CloneX App',
        address: process.env.SMTP_USER
      },
      to: userEmail,
      subject: 'Welcome to CloneX - Your Account is Ready!',
      html: welcomeTemplate,
      text: this.getWelcomeTextVersion(name, userEmail, password, credits)
    };

    try {
      const result = await this.sendEmailWithRetry(mailOptions, 'welcome');
      
      // Update statistics
      this.stats.sent++;
      this.stats.lastSent = new Date();
      this.emailsSentThisWindow++;
      
      console.log('✅ Welcome email sent successfully:', {
        messageId: result.messageId,
        to: userEmail,
        client: clientSource,
        rateLimitStatus: `${this.emailsSentThisWindow}/${this.maxEmailsPerWindow}`
      });

      return { 
        success: true, 
        messageId: result.messageId,
        to: userEmail,
        stats: this.getStats()
      };

    } catch (error) {
      console.error('❌ Failed to send welcome email:', {
        error: error.message,
        code: error.code,
        command: error.command,
        to: userEmail,
        stack: error.stack?.split('\n')[0]
      });
      
      // For timeout errors, try multiple fallback strategies
      if (error.code === 'ETIMEDOUT' || error.code === 'ECONNRESET') {
        console.log('🔄 Attempting email retry with fallback transporter...');
        try {
          // Close existing connection
          if (this.transporter && this.transporter.close) {
            await this.transporter.close();
          }
          
          // Wait before retry
          await new Promise(resolve => setTimeout(resolve, 3000));
          
          // Use fallback transporter
          console.log('🔄 Using fallback SMTP configuration...');
          const fallbackTransporter = this.createFallbackTransporter();
          
          // Retry with fallback
          const retryResult = await fallbackTransporter.sendMail(mailOptions);
          console.log('✅ Welcome email sent with fallback:', {
            messageId: retryResult.messageId,
            to: userEmail
          });
          
          // Close fallback transporter
          if (fallbackTransporter.close) {
            fallbackTransporter.close();
          }
          
          return { 
            success: true, 
            messageId: retryResult.messageId,
            to: userEmail,
            fallback: true
          };
        } catch (retryError) {
          console.error('❌ Fallback also failed:', retryError.message);
          return { 
            success: false, 
            error: retryError.message,
            originalError: error.message,
            fallbackFailed: true
          };
        }
      }
      
      return { 
        success: false, 
        error: error.message,
        code: error.code
      };
    }
  }

  // HTML email template for welcome emails
  getWelcomeTemplate(name, email, password, credits, clientSource) {
    return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Welcome to CloneX</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .credentials { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #667eea; }
            .button { display: inline-block; background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 10px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            .highlight { color: #667eea; font-weight: bold; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🎬 Welcome to CloneX!</h1>
            <p>Your AI-powered video creation account is ready</p>
        </div>
        
        <div class="content">
            // <h2>Hello ${name}! 👋</h2>
            <h2>Hello 👋</h2>
            
            <p>Great news! Your CloneX account has been automatically created following your recent purchase through our website.</p>
            
            <div class="credentials">
                <h3>🔐 Your Login Credentials:</h3>
                <p><strong>Email:</strong> ${email}</p>
                <p><strong>Password:</strong> <code>${password}</code></p>
                <p><strong>Credits:</strong> <span class="highlight">${credits} credits</span> ready to use!</p>
            </div>
            
            <h3>Getting Started:</h3>
            <ol>
                <li><strong>Download the app:</strong>
                    <br><a href="https://play.google.com/store/apps/details?id=com.clonex.video_gen_app" class="button">Download for Android</a>
                    <br><em>iOS version coming soon!</em>
                </li>
                <li><strong>Login with your credentials above</strong></li>
                <li><strong>Start creating amazing videos with AI!</strong></li>
            </ol>
            
            <h3>What You Can Do:</h3>
            <ul>
                <li>Create talking avatar videos</li>
                <li>Add AI-generated voiceovers</li>
                <li>Generate professional video content</li>
                <li>Export and share anywhere</li>
            </ul>
            
            <div style="background: #e8f4fd; padding: 15px; border-radius: 8px; margin: 20px 0;">
                <p><strong>Pro Tip:</strong> Change your password after first login for security!</p>
            </div>
            
            // <p><strong>Ye apki email hai, password ye hai - login kar ke CloneX app use karen!</strong></p>
            
            // <a href="mailto:support@clonex.com" class="button">Contact Support</a>
        </div>
        
        <div class="footer">
            <p>Happy creating! <br>
            <strong>The CloneX Team</strong></p>
            <p><em>This email was sent because you purchased credits through ${clientSource}</em></p>
        </div>
    </body>
    </html>
    `;
  }

  // Plain text version for email clients that don't support HTML
  getWelcomeTextVersion(name, email, password, credits) {
    return `
Welcome to CloneX, ${name}!

Your account has been automatically created following your recent purchase.

LOGIN CREDENTIALS:
Email: ${email}
Password: ${password}
Credits: ${credits} credits ready to use!

GETTING STARTED:
1. Download the Android app from Google Play Store
2. Login with the credentials above
3. Start creating amazing AI videos!

FEATURES:
- Create talking avatar videos
- Add AI-generated voiceovers
- Generate professional video content
- Export and share anywhere

Download the app: https://play.google.com/store/apps/details?id=com.clonex.video_gen_app

Need help? Contact us at support@videogenapp.com

Happy creating!
The CloneX Team
    `;
  }

  // Send credit addition email for existing users
  async sendExistingUserCreditEmail(userEmail, creditDetails) {
    // Production validation
    const validationResult = this.validateEmailRequest(userEmail, 'existing_user_credit');
    if (!validationResult.valid) {
      return validationResult;
    }

    // Rate limiting check
    if (this.isRateLimited()) {
      return this.queueEmail('existing_user_credit', userEmail, creditDetails);
    }

    const { credits, amount, clientSource = 'Unknown' } = creditDetails;

    const existingUserTemplate = this.getExistingUserTemplate(
      userEmail,
      credits,
      amount,
      clientSource
    );

    const mailOptions = {
      from: {
        name: process.env.EMAIL_FROM_NAME || 'CloneX CloneX',
        address: process.env.SMTP_USER
      },
      to: userEmail,
      subject: 'Credits Added to Your CloneX Account!',
      html: existingUserTemplate,
      text: this.getExistingUserTextVersion(userEmail, credits, amount)
    };

    try {
      const result = await this.sendEmailWithRetry(mailOptions, 'existing_user_credit');
      
      // Update statistics
      this.stats.sent++;
      this.stats.lastSent = new Date();
      this.emailsSentThisWindow++;
      
      console.log('✅ Existing user credit email sent successfully:', {
        messageId: result.messageId,
        to: userEmail,
        credits: credits,
        rateLimitStatus: `${this.emailsSentThisWindow}/${this.maxEmailsPerWindow}`
      });

      return { 
        success: true, 
        messageId: result.messageId,
        to: userEmail,
        stats: this.getStats()
      };

    } catch (error) {
      console.error('❌ Failed to send existing user credit email:', {
        error: error.message,
        code: error.code,
        command: error.command,
        to: userEmail,
        stack: error.stack?.split('\n')[0]
      });
      
      // For timeout errors, try multiple fallback strategies
      if (error.code === 'ETIMEDOUT' || error.code === 'ECONNRESET') {
        console.log('🔄 Attempting email retry with fallback transporter...');
        try {
          // Close existing connection
          if (this.transporter && this.transporter.close) {
            await this.transporter.close();
          }
          
          // Wait before retry
          await new Promise(resolve => setTimeout(resolve, 3000));
          
          // Use fallback transporter (direct SMTP without Gmail service)
          console.log('🔄 Using fallback SMTP configuration...');
          const fallbackTransporter = this.createFallbackTransporter();
          
          // Retry with fallback
          const retryResult = await fallbackTransporter.sendMail(mailOptions);
          console.log('✅ Existing user credit email sent with fallback:', {
            messageId: retryResult.messageId,
            to: userEmail,
            credits: creditDetails.credits
          });
          
          // Close fallback transporter
          if (fallbackTransporter.close) {
            fallbackTransporter.close();
          }
          
          return { 
            success: true, 
            messageId: retryResult.messageId,
            to: userEmail,
            fallback: true
          };
        } catch (retryError) {
          console.error('❌ Fallback also failed:', retryError.message);
          
          // Last resort: Try webhook-based email service or log for manual sending
          console.log('📧 All email methods failed, logging content for manual sending:', {
            to: userEmail,
            subject: 'Credits Added to Your CloneX Account!',
            credits: creditDetails.credits,
            amount: creditDetails.amount,
            clientSource: creditDetails.clientSource
          });
          
          // Try to send notification via webhook or database queue
          try {
            await this.queueEmailForManualSending({
              type: 'existing_user_credit',
              to: userEmail,
              data: creditDetails,
              timestamp: new Date().toISOString()
            });
          } catch (queueError) {
            console.warn('Failed to queue email:', queueError.message);
          }
          
          return { 
            success: false, 
            error: retryError.message,
            originalError: error.message,
            fallbackFailed: true,
            queued: true
          };
        }
      }
      
      return { 
        success: false, 
        error: error.message,
        code: error.code
      };
    }
  }

  // Send payment confirmation email
  async sendPaymentConfirmationEmail(userEmail, paymentDetails) {
    try {
      if (!this.initialized) {
        return { success: false, reason: 'email_service_not_configured' };
      }

      const { amount, credits, transactionId, clientSource } = paymentDetails;

      const mailOptions = {
        from: {
          name: process.env.EMAIL_FROM_NAME || 'CloneX App',
          address: process.env.SMTP_USER
        },
        to: userEmail,
        subject: 'Payment Confirmed - Credits Added to Your Account',
        html: this.getPaymentConfirmationTemplate(amount, credits, transactionId, clientSource),
        text: `Payment confirmed! $${amount} payment processed. ${credits} credits added to your account. Transaction ID: ${transactionId}`
      };

      const result = await this.transporter.sendMail(mailOptions);
      return { success: true, messageId: result.messageId };

    } catch (error) {
      console.error('❌ Failed to send payment confirmation email:', error);
      return { success: false, error: error.message };
    }
  }

  // HTML email template for existing users getting credits
  getExistingUserTemplate(userEmail, credits, amount, clientSource) {
    return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Credits Added - CloneX</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .credits-box { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #28a745; }
            .button { display: inline-block; background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 10px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            .highlight { color: #28a745; font-weight: bold; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>💰 Credits Added to Your Account!</h1>
            <p>Your CloneX account has been credited</p>
        </div>
        
        <div class="content">
            <h2>Hello! 👋</h2>
            
            <p>Great news! Your CloneX account already exists and we've added more credits to your balance.</p>
            
            <div class="credits-box">
                <h3>💳 Payment Details:</h3>
                <p><strong>Amount Paid:</strong> $${amount}</p>
                <p><strong>Credits Added:</strong> <span class="highlight">${credits} credits</span></p>
                <p><strong>Your Email:</strong> ${userEmail}</p>
                <p><strong>Purchase Source:</strong> ${clientSource}</p>
            </div>
            
            <h3>🚀 Ready to Create Videos:</h3>
            <p>This user already exists in CloneX app. <strong>Kindly login to check your updated credit balance!</strong></p>
            
            <ol>
                <li><strong>Open CloneX App:</strong>
                    <br>📱 <a href="https://play.google.com/store/apps/details?id=com.clonex.video_gen_app" class="button">Open Android App</a>
                    <br>🍎 <em>iOS version available in App Store!</em>
                </li>
                <li><strong>Login with your existing credentials</strong></li>
                <li><strong>Check your updated credit balance</strong></li>
                <li><strong>Start creating amazing videos!</strong></li>
            </ol>
            
            <h3>✨ What You Can Do:</h3>
            <ul>
                <li>🎭 Create talking avatar videos</li>
                <li>🎵 Add AI-generated voiceovers</li>
                <li>🎨 Generate professional video content</li>
                <li>📱 Export and share anywhere</li>
            </ul>
            
            <p>Your credits are ready to use! Start creating amazing videos today! 🎬</p>
            
            <a href="mailto:support@clonex.com" class="button">Contact Support</a>
        </div>
        
        <div class="footer">
            <p>Keep creating! 🎬<br>
            <strong>The CloneX Team</strong></p>
            <p><em>Credits added via ${clientSource}</em></p>
        </div>
    </body>
    </html>
    `;
  }

  // Plain text version for existing users
  getExistingUserTextVersion(userEmail, credits, amount) {
    return `
Credits Added to Your CloneX Account!

Hello!

Your CloneX account already exists and we've added more credits.

PAYMENT DETAILS:
Amount: $${amount}
Credits Added: ${credits} credits
Email: ${userEmail}

NEXT STEPS:
This user already exists in CloneX app. Kindly login to check your updated credit balance!

1. Open CloneX app on your device
2. Login with your existing credentials  
3. Check your updated credit balance
4. Start creating amazing videos!

Your credits are ready to use!

Need help? Contact us at support@clonex.com

The CloneX Team
    `;
  }

  // Payment confirmation email template
  getPaymentConfirmationTemplate(amount, credits, transactionId, clientSource) {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #28a745; color: white; padding: 20px; text-align: center; border-radius: 8px; }
            .content { padding: 20px; background: #f8f9fa; border-radius: 8px; margin-top: 10px; }
            .highlight { color: #28a745; font-weight: bold; }
        </style>
    </head>
    <body>
        <div class="header">
            <h2>✅ Payment Confirmed!</h2>
        </div>
        <div class="content">
            <p>Your payment has been successfully processed through <strong>${clientSource}</strong>.</p>
            
            <h3>Payment Details:</h3>
            <ul>
                <li><strong>Amount:</strong> $${amount}</li>
                <li><strong>Credits Added:</strong> <span class="highlight">${credits} credits</span></li>
                <li><strong>Transaction ID:</strong> ${transactionId}</li>
            </ul>
            
            <p>Your credits are now available in your CloneX app account!</p>
            
            <p>Start creating amazing videos today! 🎬</p>
        </div>
    </body>
    </html>
    `;
  }

  // Production health check
  async healthCheck() {
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      initialized: this.initialized,
      stats: this.getStats(),
      transporter: {
        primary: false,
        fallback: false
      },
      environment: this.isProduction ? 'production' : 'development'
    };

    // Test primary transporter
    try {
      if (this.transporter) {
        await this.transporter.verify();
        health.transporter.primary = true;
      }
    } catch (error) {
      console.warn('Primary transporter health check failed:', error.message);
      health.status = 'degraded';
    }

    // Test fallback transporter
    try {
      if (this.fallbackTransporter) {
        await this.fallbackTransporter.verify();
        health.transporter.fallback = true;
      }
    } catch (error) {
      console.warn('Fallback transporter health check failed:', error.message);
      if (!health.transporter.primary) {
        health.status = 'unhealthy';
      }
    }

    return health;
  }

  // Admin method to clear email queue
  clearQueue() {
    const queueLength = this.emailQueue.length;
    this.emailQueue = [];
    console.log(`📬 Email queue cleared: ${queueLength} emails removed`);
    return { cleared: queueLength };
  }

  // Admin method to force process queue
  async forceProcessQueue() {
    console.log('🚀 Force processing email queue...');
    const originalRateLimit = this.maxEmailsPerWindow;
    this.maxEmailsPerWindow = 1000; // Temporarily increase limit
    
    await this.processEmailQueue();
    
    this.maxEmailsPerWindow = originalRateLimit;
    return { processed: true, remaining: this.emailQueue.length };
  }

  // Admin method to send test email
  async sendTestEmail(testEmail = 'test@example.com') {
    if (this.isProduction && testEmail.includes('example.com')) {
      return { error: 'Cannot send to example.com in production' };
    }

    const testMailOptions = {
      from: {
        name: process.env.EMAIL_FROM_NAME || 'CloneX App',
        address: process.env.SMTP_USER
      },
      to: testEmail,
      subject: `CloneX Email Service Test - ${new Date().toISOString()}`,
      html: `
        <h2>Email Service Test</h2>
        <p>This is a test email from CloneX email service.</p>
        <p><strong>Environment:</strong> ${this.isProduction ? 'Production' : 'Development'}</p>
        <p><strong>Timestamp:</strong> ${new Date().toISOString()}</p>
        <p><strong>Stats:</strong> ${JSON.stringify(this.getStats(), null, 2)}</p>
      `,
      text: `CloneX Email Service Test - ${new Date().toISOString()}`
    };

    try {
      const result = await this.sendEmailWithRetry(testMailOptions, 'test');
      return { 
        success: true, 
        messageId: result.messageId,
        to: testEmail,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return { 
        success: false, 
        error: error.message,
        to: testEmail,
        timestamp: new Date().toISOString()
      };
    }
  }
}

// Export singleton instance
module.exports = new EmailService();