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
        }
      });

      // Verify connection
      if (process.env.SMTP_USER && process.env.SMTP_PASS) {
        await this.transporter.verify();
        console.log('✅ Email service initialized successfully');
        this.initialized = true;
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
          name: process.env.EMAIL_FROM_NAME || 'Video Generator App',
          address: process.env.SMTP_USER
        },
        to: userEmail,
        subject: 'Welcome to Video Generator - Your Account is Ready!',
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
        <title>Welcome to Video Generator</title>
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
            <h1>🎬 Welcome to Video Generator!</h1>
            <p>Your AI-powered video creation account is ready</p>
        </div>
        
        <div class="content">
            <h2>Hello ${name}! 👋</h2>
            
            <p>Great news! Your Video Generator account has been automatically created following your recent purchase through <strong>${clientSource}</strong>.</p>
            
            <div class="credentials">
                <h3>🔐 Your Login Credentials:</h3>
                <p><strong>Email:</strong> ${email}</p>
                <p><strong>Password:</strong> <code>${password}</code></p>
                <p><strong>Credits:</strong> <span class="highlight">${credits} credits</span> ready to use!</p>
            </div>
            
            <h3>🚀 Getting Started:</h3>
            <ol>
                <li><strong>Download the app:</strong>
                    <br>📱 <a href="https://play.google.com/store/apps/details?id=com.clonex.video_gen_app" class="button">Download for Android</a>
                    <br>🍎 <em>iOS version coming soon!</em>
                </li>
                <li><strong>Login with your credentials above</strong></li>
                <li><strong>Start creating amazing videos with AI!</strong></li>
            </ol>
            
            <h3>✨ What You Can Do:</h3>
            <ul>
                <li>🎭 Create talking avatar videos</li>
                <li>🎵 Add AI-generated voiceovers</li>
                <li>🎨 Generate professional video content</li>
                <li>📱 Export and share anywhere</li>
            </ul>
            
            <div style="background: #e8f4fd; padding: 15px; border-radius: 8px; margin: 20px 0;">
                <p><strong>💡 Pro Tip:</strong> Change your password after first login for security!</p>
            </div>
            
            <p>If you have any questions or need help getting started, our support team is here to help!</p>
            
            <a href="mailto:support@videogenapp.com" class="button">Contact Support</a>
        </div>
        
        <div class="footer">
            <p>Happy creating! 🎬<br>
            <strong>The Video Generator Team</strong></p>
            <p><em>This email was sent because you purchased credits through ${clientSource}</em></p>
        </div>
    </body>
    </html>
    `;
  }

  // Plain text version for email clients that don't support HTML
  getWelcomeTextVersion(name, email, password, credits) {
    return `
Welcome to Video Generator, ${name}!

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
The Video Generator Team
    `;
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
          name: process.env.EMAIL_FROM_NAME || 'Video Generator App',
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
            
            <p>Your credits are now available in your Video Generator app account!</p>
            
            <p>Start creating amazing videos today! 🎬</p>
        </div>
    </body>
    </html>
    `;
  }
}

// Export singleton instance
module.exports = new EmailService();