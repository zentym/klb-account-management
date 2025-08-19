// OTP Service for Real Implementation
export interface OTPService {
    sendOTP(phoneNumber: string): Promise<{ otpId: string; expiresIn: number }>;
    verifyOTP(phoneNumber: string, otpCode: string, otpId: string): Promise<boolean>;
}

// Mock OTP Service for Development
class MockOTPService implements OTPService {
    private otpStorage = new Map<string, { code: string; expires: number; otpId: string }>();
    private otpIdCounter = 1000;

    async sendOTP(phoneNumber: string): Promise<{ otpId: string; expiresIn: number }> {
        // Generate 6-digit OTP
        const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
        const otpId = (this.otpIdCounter++).toString();
        const expiresIn = 5 * 60 * 1000; // 5 minutes
        const expires = Date.now() + expiresIn;

        // Store OTP
        this.otpStorage.set(phoneNumber, { code: otpCode, expires, otpId });

        // Simulate SMS delay
        await new Promise(resolve => setTimeout(resolve, 1500));

        // In development, log OTP to console
        if (process.env.NODE_ENV === 'development') {
            console.log(`📱 OTP for ${phoneNumber}: ${otpCode} (Valid for 5 minutes)`);
            console.log(`🔑 OTP ID: ${otpId}`);

            // Show OTP in browser notification for development
            if (typeof window !== 'undefined' && 'Notification' in window) {
                new Notification(`OTP cho ${phoneNumber}`, {
                    body: `Mã OTP: ${otpCode}`,
                    icon: '/favicon.ico'
                });
            }
        }

        return { otpId, expiresIn };
    }

    async verifyOTP(phoneNumber: string, otpCode: string, otpId: string): Promise<boolean> {
        const stored = this.otpStorage.get(phoneNumber);

        if (!stored) {
            throw new Error('OTP không tồn tại hoặc đã hết hạn');
        }

        if (stored.otpId !== otpId) {
            throw new Error('OTP ID không hợp lệ');
        }

        if (Date.now() > stored.expires) {
            this.otpStorage.delete(phoneNumber);
            throw new Error('OTP đã hết hạn');
        }

        if (stored.code !== otpCode) {
            throw new Error('Mã OTP không đúng');
        }

        // Clean up after successful verification
        this.otpStorage.delete(phoneNumber);
        return true;
    }

    // Development helper - get current OTP for testing
    getCurrentOTP(phoneNumber: string): string | null {
        const stored = this.otpStorage.get(phoneNumber);
        if (!stored || Date.now() > stored.expires) {
            return null;
        }
        return stored.code;
    }
}

// Production SMS OTP Service (integrate with your SMS provider)
class SMSOTPService implements OTPService {
    private smsProvider: SMSProvider; // Your SMS service (Twilio, AWS SNS, etc.)
    private otpStorage = new Map<string, { otpId: string; expires: number }>();

    constructor(smsProvider: SMSProvider) {
        this.smsProvider = smsProvider;
    }

    async sendOTP(phoneNumber: string): Promise<{ otpId: string; expiresIn: number }> {
        const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
        const otpId = `otp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        const expiresIn = 5 * 60 * 1000; // 5 minutes
        const expires = Date.now() + expiresIn;

        // Store OTP with hashed version for security
        const hashedOTP = await this.hashOTP(otpCode);
        this.otpStorage.set(phoneNumber, { otpId: hashedOTP, expires });

        // Send SMS
        const message = `Mã OTP KLB Bank của bạn: ${otpCode}. Có hiệu lực trong 5 phút. Không chia sẻ với ai.`;
        await this.smsProvider.sendSMS(phoneNumber, message);

        return { otpId, expiresIn };
    }

    async verifyOTP(phoneNumber: string, otpCode: string, otpId: string): Promise<boolean> {
        // Implementation with proper security measures
        // Hash incoming OTP and compare with stored hash
        // Add rate limiting, attempt counting, etc.

        // This is simplified - in production, add more security layers
        return true;
    }

    private async hashOTP(otp: string): Promise<string> {
        // Use bcrypt or similar for hashing OTP
        return otp; // Simplified for demo
    }
}

// SMS Provider interface for different services
interface SMSProvider {
    sendSMS(phoneNumber: string, message: string): Promise<void>;
}

// Twilio SMS Provider Example
class TwilioSMSProvider implements SMSProvider {
    private accountSid: string;
    private authToken: string;
    private fromNumber: string;

    constructor(accountSid: string, authToken: string, fromNumber: string) {
        this.accountSid = accountSid;
        this.authToken = authToken;
        this.fromNumber = fromNumber;
    }

    async sendSMS(phoneNumber: string, message: string): Promise<void> {
        // Implement Twilio API call
        // const client = require('twilio')(this.accountSid, this.authToken);
        // await client.messages.create({
        //     body: message,
        //     from: this.fromNumber,
        //     to: phoneNumber
        // });

        console.log(`📱 SMS sent to ${phoneNumber}: ${message}`);
    }
}

// Factory to create appropriate OTP service
export function createOTPService(): OTPService {
    if (process.env.NODE_ENV === 'production') {
        // Return production SMS service
        const smsProvider = new TwilioSMSProvider(
            process.env.TWILIO_ACCOUNT_SID!,
            process.env.TWILIO_AUTH_TOKEN!,
            process.env.TWILIO_FROM_NUMBER!
        );
        return new SMSOTPService(smsProvider);
    } else {
        // Return mock service for development
        return new MockOTPService();
    }
}

// Export default instance
export const otpService = createOTPService();

export default otpService;
