const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    this.transporter = null;
    this.initialized = false;
  }

  // Initialize the email service with configuration
  async init() {
    try {
      // Create transporter with environment variables
      this.transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: parseInt(process.env.SMTP_PORT) || 587,
        secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS
        },
        tls: {
          rejectUnauthorized: false
        },
        connectionTimeout: 10000, // 10 seconds
        greetingTimeout: 5000, // 5 seconds
        socketTimeout: 10000 // 10 seconds
      });

      // Verify connection with timeout
      if (process.env.SMTP_USER && process.env.SMTP_PASS) {
        try {
          // Set verification timeout
          const verificationPromise = this.transporter.verify();
          const timeoutPromise = new Promise((_, reject) => 
            setTimeout(() => reject(new Error('Verification timeout')), 5000)
          );
          
          await Promise.race([verificationPromise, timeoutPromise]);
          console.log('✅ Email service initialized successfully');
          this.initialized = true;
        } catch (verifyError) {
          console.log('⚠️ Email verification failed, but service will still try to send:', verifyError.message);
          this.initialized = true; // Still try to send emails
        }
      } else {
        console.log('⚠️ Email service not configured - SMTP credentials missing');
        this.initialized = false;
      }

    } catch (error) {
      console.error('❌ Email service initialization failed:', error.message);
      this.initialized = false;
    }
  }

  // Send welcome email to new client users
  async sendWelcomeEmail(userEmail, userCredentials, clientInfo = {}) {
    try {
      if (!this.initialized) {
        console.log('⚠️ Email service not initialized - skipping email');
        return { success: false, reason: 'email_service_not_configured' };
      }

      // Skip sending to test/example domains
      const testDomains = ['example.com', 'test.com', 'localhost'];
      const emailDomain = userEmail.split('@')[1]?.toLowerCase();
      
      if (testDomains.includes(emailDomain)) {
        console.log(`⚠️ Skipping email to test domain: ${emailDomain}`);
        return { 
          success: true, 
          reason: 'test_domain_skipped',
          message: `Email not sent to test domain: ${emailDomain}`
        };
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

      const result = await this.transporter.sendMail(mailOptions);
      
      console.log('✅ Welcome email sent successfully:', {
        messageId: result.messageId,
        to: userEmail,
        client: clientSource
      });

      return { 
        success: true, 
        messageId: result.messageId,
        to: userEmail 
      };

    } catch (error) {
      console.error('❌ Failed to send welcome email:', error);
      return { 
        success: false, 
        error: error.message 
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
    try {
      if (!this.initialized) {
        console.log('⚠️ Email service not initialized - skipping email');
        return { success: false, reason: 'email_service_not_configured' };
      }

      // Skip sending to test/example domains
      const testDomains = ['example.com', 'test.com', 'localhost'];
      const emailDomain = userEmail.split('@')[1]?.toLowerCase();
      
      if (testDomains.includes(emailDomain)) {
        console.log(`⚠️ Skipping email to test domain: ${emailDomain}`);
        return { 
          success: true, 
          reason: 'test_domain_skipped',
          message: `Email not sent to test domain: ${emailDomain}`
        };
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

      const result = await this.transporter.sendMail(mailOptions);
      
      console.log('✅ Existing user credit email sent successfully:', {
        messageId: result.messageId,
        to: userEmail,
        credits: credits
      });

      return { 
        success: true, 
        messageId: result.messageId,
        to: userEmail 
      };

    } catch (error) {
      console.error('❌ Failed to send existing user credit email:', error);
      return { 
        success: false, 
        error: error.message 
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
}

// Export singleton instance
module.exports = new EmailService();