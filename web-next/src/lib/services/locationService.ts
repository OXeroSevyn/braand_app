import { supabase } from '../supabase';

export interface OfficeLocation {
    id: string;
    name: string;
    latitude: number;
    longitude: number;
    radius_meters: number;
}

export interface LocationStatus {
    isInRange: boolean;
    distanceToNearest: number;
    nearestOfficeName?: string;
    message: string;
}

class LocationService {
    private cachedOffices: OfficeLocation[] | null = null;
    private lastFetchTime: number | null = null;
    private readonly CACHE_DURATION = 60 * 60 * 1000; // 1 hour

    async getOfficeLocations(forceRefresh = false): Promise<OfficeLocation[]> {
        const now = Date.now();
        if (!forceRefresh && this.cachedOffices && this.lastFetchTime && (now - this.lastFetchTime < this.CACHE_DURATION)) {
            return this.cachedOffices;
        }

        const { data, error } = await supabase
            .from('office_locations')
            .select('*')
            .eq('is_active', true);

        if (error) {
            console.error('Error fetching office locations:', error);
            return this.cachedOffices || [];
        }

        this.cachedOffices = data as OfficeLocation[];
        this.lastFetchTime = now;
        return this.cachedOffices;
    }

    getCurrentPosition(): Promise<GeolocationPosition> {
        return new Promise((resolve, reject) => {
            if (!navigator.geolocation) {
                reject(new Error('Geolocation is not supported by your browser'));
                return;
            }

            navigator.geolocation.getCurrentPosition(resolve, reject, {
                enableHighAccuracy: true,
                timeout: 10000,
                maximumAge: 0,
            });
        });
    }

    calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
        const R = 6371e3; // Earth radius in meters
        const phi1 = (lat1 * Math.PI) / 180;
        const phi2 = (lat2 * Math.PI) / 180;
        const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
        const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

        const a =
            Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
            Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c;
    }

    async checkLocationStatus(): Promise<LocationStatus> {
        try {
            const position = await this.getCurrentPosition();
            const { latitude, longitude } = position.coords;
            const offices = await this.getOfficeLocations();

            if (offices.length === 0) {
                return { isInRange: true, distanceToNearest: 0, message: 'No offices configured' };
            }

            let nearest: OfficeLocation | null = null;
            let minDistance = Infinity;

            for (const office of offices) {
                const distance = this.calculateDistance(latitude, longitude, office.latitude, office.longitude);
                if (distance < minDistance) {
                    minDistance = distance;
                    nearest = office;
                }
            }

            if (nearest) {
                const isInRange = minDistance <= nearest.radius_meters;
                return {
                    isInRange,
                    distanceToNearest: minDistance,
                    nearestOfficeName: nearest.name,
                    message: isInRange
                        ? `You are at ${nearest.name}`
                        : `You are ${Math.round(minDistance)}m away from ${nearest.name}`,
                };
            }

            return { isInRange: false, distanceToNearest: 0, message: 'No office found' };
        } catch (error) {
            const message = error instanceof Error ? error.message : 'Error checking location';
            return { isInRange: false, distanceToNearest: 0, message };
        }
    }
}

export const locationService = new LocationService();
