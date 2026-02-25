import { supabase } from '../supabase';
import { locationService } from './locationService';
import { deviceService } from './deviceService';

export enum AttendanceType {
    CLOCK_IN = 'AttendanceType.CLOCK_IN',
    CLOCK_OUT = 'AttendanceType.CLOCK_OUT',
    BREAK_START = 'AttendanceType.BREAK_START',
    BREAK_END = 'AttendanceType.BREAK_END',
}

export interface AttendanceRecord {
    id?: string;
    user_id: string;
    type: AttendanceType;
    timestamp: number;
    location_lat?: number;
    location_lng?: number;
    device_id?: string;
    biometric_verified?: boolean;
    verification_method?: string;
}

export interface AttendanceStats {
    presentDays: number;
    lateDays: number;
    absentDays: number;
    averageHours: number;
    totalWorkingDays: number;
}

class AttendanceService {
    async getUserRecords(userId: string, limit = 50): Promise<AttendanceRecord[]> {
        const { data, error } = await supabase
            .from('attendance_records')
            .select('*')
            .eq('user_id', userId)
            .order('timestamp', { ascending: false })
            .limit(limit);

        if (error) {
            console.error('Error fetching attendance records:', error);
            return [];
        }

        return data as AttendanceRecord[];
    }

    async getAttendanceStats(userId: string): Promise<AttendanceStats | null> {
        const now = new Date();
        const year = now.getFullYear();
        const month = now.getMonth() + 1;

        // Use a RPC or fetch and calculate
        const startOfMonth = new Date(year, month - 1, 1).getTime();

        const { data, error } = await supabase
            .from('attendance_records')
            .select('*')
            .eq('user_id', userId)
            .gte('timestamp', startOfMonth);

        if (error) {
            console.error('Error fetching stats data:', error);
            return null;
        }

        // Basic calculation logic
        const records = data as AttendanceRecord[];
        const daysWithRecords = new Set(records.map(r => new Date(r.timestamp).toDateString())).size;

        // Placeholder values until we implement full logic
        return {
            presentDays: daysWithRecords,
            lateDays: 0,
            absentDays: 0,
            averageHours: 8.5,
            totalWorkingDays: 22,
        };
    }

    async logAttendance(userId: string, type: AttendanceType): Promise<{ success: boolean; error?: string }> {
        try {
            if (globalThis.window === undefined) return { success: false, error: 'Cannot log attendance from server' };

            // 1. Device Check
            const isRegistered = await deviceService.isDeviceRegistered(userId);
            if (!isRegistered) {
                return { success: false, error: 'Device not registered. Please register this browser in settings.' };
            }

            // 2. Location Check
            const locationStatus = await locationService.checkLocationStatus();
            if (!locationStatus.isInRange) {
                return { success: false, error: locationStatus.message };
            }

            // 3. Get Coords
            const pos = await locationService.getCurrentPosition();

            const record: AttendanceRecord = {
                user_id: userId,
                type,
                timestamp: Date.now(),
                location_lat: pos.coords.latitude,
                location_lng: pos.coords.longitude,
                device_id: deviceService.getDeviceId(),
                verification_method: 'Web-Geolocation',
            };

            const { error } = await supabase.from('attendance_records').insert(record);

            if (error) throw error;

            await deviceService.updateLastUsed(userId);
            return { success: true };
        } catch (error) {
            const message = error instanceof Error ? error.message : 'Failed to log attendance';
            return { success: false, error: message };
        }
    }

    async startBreak(userId: string) {
        return this.logAttendance(userId, AttendanceType.BREAK_START);
    }

    async endBreak(userId: string) {
        return this.logAttendance(userId, AttendanceType.BREAK_END);
    }
}

export const attendanceService = new AttendanceService();
