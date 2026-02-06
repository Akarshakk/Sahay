import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
    private transporter: nodemailer.Transporter;
    private readonly logger = new Logger(MailService.name);

    constructor(private readonly configService: ConfigService) {
        this.createTransport();
    }

    private createTransport() {
        const host = this.configService.get<String>('SMTP_HOST');
        const user = this.configService.get<String>('SMTP_USER');

        if (!host || !user) {
            this.logger.warn('SMTP Configuration missing. Mails will fail unless mocked.');
        }

        this.transporter = nodemailer.createTransport({
            host: this.configService.get('SMTP_HOST'),
            port: Number(this.configService.get('SMTP_PORT')) || 587,
            secure: this.configService.get('SMTP_SECURE') === 'true',
            auth: {
                user: this.configService.get('SMTP_USER'),
                pass: this.configService.get('SMTP_PASS'),
            },
        });
    }

    async sendOtp(email: string, otp: string) {
        const from = this.configService.get('SMTP_FROM') || '"CivicSync" <noreply@civicsync.com>';
        const host = this.configService.get('SMTP_HOST');

        // Fallback for development if SMTP is not configured
        if (!host) {
            this.logger.warn(`SMTP_HOST not set. Mocking email to ${email}`);
            this.logger.log(`===============================================`);
            this.logger.log(`🔐 OTP for ${email}: ${otp}`);
            this.logger.log(`===============================================`);
            return true;
        }

        try {
            const info = await this.transporter.sendMail({
                from,
                to: email,
                subject: 'Your Verification Code',
                text: `Your verification code is: ${otp}`,
                html: `
            <div style="font-family: Arial, sans-serif; padding: 20px;">
            <h2>Verification Code</h2>
            <p>Your code is: <strong>${otp}</strong></p>
            <p>This code expires in 10 minutes.</p>
            </div>
        `,
            });
            this.logger.log(`Email sent: ${info.messageId}`);
            return true;
        } catch (error) {
            this.logger.error(`Failed to send email: ${error.message}`, error.stack);
            // Fallback or Rethrow? 
            // User said "no loose end". If email fails, user cannot verify. 
            // We should throw so frontend shows error.
            throw error;
        }
    }
}
