import { supabase } from '../supabase';

class DeviceService {
    private readonly STORAGE_KEY = 'braand_device_id';

    getDeviceId(): string {
        if (typeof globalThis.window === 'undefined') return 'server';
        let deviceId = localStorage.getItem(this.STORAGE_KEY);
        if (!deviceId) {
            deviceId = `web_${crypto.randomUUID()}`;
            localStorage.setItem(this.STORAGE_KEY, deviceId);
        }
        return deviceId;
    }

    async isDeviceRegistered(userId: string): Promise<boolean> {
        const deviceId = this.getDeviceId();
        const { data, error } = await supabase
            .from('device_bindings')
            .select('id')
            .eq('user_id', userId)
            .eq('device_id', deviceId)
            .eq('is_active', true)
            .maybeSingle();

        if (error) {
            console.error('Error checking device registration:', error);
            return false;
        }

        return !!data;
    }

    async registerDevice(userId: string): Promise<boolean> {
        const deviceId = this.getDeviceId();
        const userAgent = navigator.userAgent;

        // Simple browser identification
        const deviceName = 'Web Browser';
        const deviceModel = userAgent.split(')')[0].split('(')[1] || 'Unknown';

        const { error } = await supabase
            .from('device_bindings')
            .insert({
                user_id: userId,
                device_id: deviceId,
                device_name: deviceName,
                device_model: deviceModel,
                registered_at: new Date().toISOString(),
                is_active: true,
            });

        if (error) {
            console.error('Error registering device:', error);
            return false;
        }

        return true;
    }

    async updateLastUsed(userId: string): Promise<void> {
        const deviceId = this.getDeviceId();
        await supabase
            .from('device_bindings')
            .update({ last_used_at: new Date().toISOString() })
            .eq('user_id', userId)
            .eq('device_id', deviceId);
    }
}

export const deviceService = new DeviceService();
