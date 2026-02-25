import { motion } from "framer-motion";
import { GlassCard } from "../../ui/GlassCard";
import { LogIn, LogOut, Loader2, MapPin, AlertCircle } from "lucide-react";
import { useEffect, useState } from "react";
import { locationService, LocationStatus } from "../../../lib/services/locationService";

interface AttendanceHeaderProps {
    readonly isClockedIn: boolean;
    readonly clockInTime: Date | null;
    readonly onClockToggle: () => void;
    readonly isLoading: boolean;
}

export function AttendanceHeader({
    isClockedIn,
    clockInTime,
    onClockToggle,
    isLoading
}: AttendanceHeaderProps) {
    const [locStatus, setLocStatus] = useState<LocationStatus | null>(null);
    const [currentTime, setCurrentTime] = useState(new Date());

    useEffect(() => {
        const timer = setInterval(() => setCurrentTime(new Date()), 1000);
        checkLocation();
        return () => clearInterval(timer);
    }, []);

    const checkLocation = async () => {
        const status = await locationService.checkLocationStatus();
        setLocStatus(status);
    };

    const formattedTime = currentTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
    const formattedDate = currentTime.toLocaleDateString([], { weekday: 'long', month: 'long', day: 'numeric' });

    const isOutOfRange = !isClockedIn && locStatus?.isInRange === false;

    return (
        <GlassCard className="p-8 overflow-hidden relative">
            {/* Background Accent */}
            <div className="absolute top-0 right-0 w-64 h-64 bg-aura-1/10 blur-[100px] -z-10 rounded-full translate-x-1/2 -translate-y-1/2" />

            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-8">
                <div>
                    <motion.div
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        className="flex items-center gap-3 mb-4"
                    >
                        <span className="px-3 py-1 rounded-full bg-white/5 border border-white/10 text-[10px] font-mono text-white/40 uppercase tracking-[0.2em]">
                            Verification Active
                        </span>
                        {locStatus && (
                            <span className={`flex items-center gap-1 text-[10px] font-mono uppercase tracking-widest ${locStatus.isInRange ? 'text-emerald-400' : 'text-rose-400'}`}>
                                <MapPin className="w-3 h-3" />
                                {locStatus.isInRange ? 'In Range' : 'Out of Range'}
                            </span>
                        )}
                    </motion.div>

                    <h1 className="text-4xl md:text-5xl font-bold text-white tracking-tight mb-2">
                        {isClockedIn ? "Session Active" : "Time Tracking"}
                    </h1>
                    <p className="text-white/50 font-medium text-lg">
                        {formattedDate} • <span className="text-white font-mono">{formattedTime}</span>
                    </p>
                </div>

                <div className="flex items-center gap-6">
                    {isClockedIn && clockInTime && (
                        <div className="text-right hidden sm:block">
                            <p className="text-white/30 text-xs font-mono uppercase tracking-widest mb-1">Started At</p>
                            <p className="text-xl font-bold text-white">
                                {clockInTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                            </p>
                        </div>
                    )}

                    <motion.button
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                        onClick={onClockToggle}
                        disabled={isLoading || isOutOfRange}
                        className={`relative group px-8 py-4 rounded-2xl flex items-center gap-3 font-bold transition-all duration-500 overflow-hidden
                            ${isClockedIn
                                ? 'bg-white text-black hover:bg-white/90'
                                : 'bg-gradient-to-r from-aura-1 to-aura-2 text-white shadow-lg shadow-aura-1/20'
                            }
                            ${(isLoading || isOutOfRange) ? 'opacity-50 cursor-not-allowed grayscale' : ''}
                        `}
                    >
                        {isLoading ? (
                            <Loader2 className="w-5 h-5 animate-spin" />
                        ) : isClockedIn ? (
                            <LogOut className="w-5 h-5" />
                        ) : (
                            <LogIn className="w-5 h-5" />
                        )}
                        <span className="relative z-10">
                            {isLoading ? 'Verifying...' : isClockedIn ? 'Clock Out' : 'Clock In Now'}
                        </span>
                    </motion.button>
                </div>
            </div>

            {isOutOfRange && (
                <motion.p
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    className="mt-6 text-rose-400 text-sm flex items-center gap-2 bg-rose-400/10 p-3 rounded-xl border border-rose-400/20"
                >
                    <AlertCircle className="w-4 h-4" />
                    {locStatus?.message}
                </motion.p>
            )}
        </GlassCard>
    );
}
