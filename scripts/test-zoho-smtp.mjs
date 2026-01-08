// Test Zoho SMTP connection
import nodemailer from 'nodemailer';

const config = {
  host: 'smtppro.zoho.com',
  port: 587,
  secure: false, // true for 465, false for other ports
  auth: {
    user: 'support@inthebiz.app',
    pass: 'Benderbender111!',
  },
};

console.log('Testing Zoho SMTP connection...');
console.log(`Host: ${config.host}:${config.port}`);
console.log(`User: ${config.auth.user}`);
console.log('');

try {
  const transporter = nodemailer.createTransport(config);

  // Verify connection
  console.log('Verifying SMTP connection...');
  await transporter.verify();
  console.log('✅ SMTP connection verified successfully!');
  console.log('');

  // Send test email
  console.log('Sending test email...');
  const info = await transporter.sendMail({
    from: '"In The Biz AI - Test" <support@inthebiz.app>',
    to: 'support@inthebiz.app',
    subject: '✅ Zoho SMTP Test - Connection Successful',
    html: `
      <h2>🎉 Zoho SMTP Test Successful!</h2>
      <p>This is a test email to verify that the Zoho SMTP integration is working correctly.</p>
      <p><strong>Sent:</strong> ${new Date().toLocaleString()}</p>
      <hr>
      <p style="color: #666; font-size: 12px;">
        This is an automated test from In The Biz AI setup.
      </p>
    `,
  });

  console.log('✅ Test email sent successfully!');
  console.log(`Message ID: ${info.messageId}`);
  console.log('');
  console.log('Check your inbox at support@inthebiz.app');
  console.log('The email should arrive within a few seconds.');
} catch (error) {
  console.error('❌ Test failed:', error.message);
  if (error.code) {
    console.error(`Error code: ${error.code}`);
  }
  if (error.response) {
    console.error(`Server response: ${error.response}`);
  }
  process.exit(1);
}
