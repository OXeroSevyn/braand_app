"use client";

import { motion } from "framer-motion";
import { GlassCard } from "../../ui/GlassCard";
import { LogIn, LogOut, Loader2, MapPin, AlertCircle, Coffee } from "lucide-react";
import { useEffect, useState } from "react";
import { locationService, LocationStatus } from "../../../lib/services/locationService";
import { cn } from "@/lib/utils";

interface AttendanceHeaderProps {
    readonly isClockedIn: boolean;
    readonly clockInTime: Date | null;
    readonly isOnBreak: boolean;
    readonly onClockToggle: () => void;
    readonly onBreakToggle: () => void;
    readonly isLoading: boolean;
}

export function AttendanceHeader({
    isClockedIn,
    clockInTime,
    isOnBreak,
    onClockToggle,
    onBreakToggle,
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
    const formattedDate = currentTime.toLocaleDateString([], { weekday: 'long', month: 'long', day: 'numeric' }).toUpperCase();

    const isOutOfRange = !isClockedIn && locStatus?.isInRange === false;

    // Status Logic
    let statusText = 'OFF DUTY';
    if (isOnBreak) statusText = 'ON BREAK';
    else if (isClockedIn) statusText = 'ON DUTY';

    const headerTitle = isClockedIn ? (isOnBreak ? "Break Active" : "Session Active") : "Time Tracker";

    const statusClasses = (isClockedIn || isOnBreak)
        ? "bg-rose-400/20 border-rose-400/40 text-rose-400"
        : "bg-neon-green/20 border-neon-green/40 text-neon-green";

    const breakButtonClasses = cn(
        "h-14 px-8 rounded-2xl font-black uppercase tracking-wider text-sm transition-all flex items-center gap-3",
        isOnBreak ? "bg-white text-black shadow-lg" : "bg-white/10 text-white border border-white/10 hover:bg-white/20"
    );

    const clockButtonClasses = cn(
        "h-14 px-10 rounded-2xl font-black uppercase tracking-wider text-sm transition-all flex items-center gap-3 relative overflow-hidden group",
        isClockedIn
            ? "bg-rose-500 text-white shadow-[0_8px_20px_-4px_rgba(244,63,94,0.4)]"
            : "bg-gradient-to-br from-neon-green to-brand-secondary text-black shadow-[0_8px_20px_-4px_rgba(167,254,43,0.4)]",
        (isLoading || isOutOfRange || isOnBreak) && "opacity-50 cursor-not-allowed grayscale"
    );

    const rangePillClasses = cn(
        "flex items-center gap-2 text-[10px] font-black uppercase tracking-widest px-4 py-1.5 rounded-lg border",
        locStatus?.isInRange
            ? "bg-emerald-400/10 border-emerald-400/30 text-emerald-400"
            : "bg-rose-400/10 border-rose-400/30 text-rose-400"
    );

    return (
        <GlassCard className="p-8 overflow-hidden relative border-white/10 bg-transparent">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-8">
                <div className="space-y-4">
                    <motion.div
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        className="flex items-center gap-3"
                    >
                        <span className="px-4 py-1.5 rounded-lg border border-neon-green/30 bg-neon-green/10 text-[10px] font-black uppercase tracking-[0.2em] text-neon-green">
                            LIVE TRACKING
                        </span>
                        {locStatus && (
                            <span className={rangePillClasses}>
                                <MapPin className="w-3.5 h-3.5" />
                                {locStatus.isInRange ? 'In Range' : 'Out of Range'}
                            </span>
                        )}
                    </motion.div>

                    <div>
                        <h1 className="text-4xl md:text-5xl font-black text-white tracking-tighter uppercase italic leading-none mb-2">
                            {headerTitle}
                        </h1>
                        <div className="flex items-center gap-3">
                            <span className={cn("px-3 py-1 rounded-md text-[10px] font-black uppercase border", statusClasses)}>
                                {statusText}
                            </span>
                            <p className="text-white/60 font-bold text-sm uppercase tracking-tight">
                                {formattedTime} <span className="text-white/20 px-1">//</span> {formattedDate}
                            </p>
                        </div>
                    </div>
                </div>

                <div className="flex flex-wrap items-center gap-4">
                    {isClockedIn && (
                        <motion.button
                            whileHover={{ scale: 1.02 }}
                            whileTap={{ scale: 0.98 }}
                            onClick={onBreakToggle}
                            disabled={isLoading}
                            className={breakButtonClasses}
                        >
                            <Coffee className="w-5 h-5" />
                            {isOnBreak ? "End Break" : "Start Break"}
                        </motion.button>
                    )}

                    <motion.button
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                        onClick={onClockToggle}
                        disabled={isLoading || isOutOfRange || isOnBreak}
                        className={clockButtonClasses}
                    >
                        {isLoading ? (
                            <Loader2 className="w-5 h-5 animate-spin" />
                        ) : isClockedIn ? (
                            <LogOut className="w-5 h-5" />
                        ) : (
                            <LogIn className="w-5 h-5" />
                        )}
                        <span>{isLoading ? "Verifying..." : isClockedIn ? "Clock Out" : "Clock In Now"}</span>
                    </motion.button>
                </div>
            </div>

            {isOutOfRange && (
                <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    className="mt-8 flex items-center gap-3 bg-rose-400/10 border border-rose-400/30 p-4 rounded-2xl text-rose-400 text-xs font-black uppercase italic"
                >
                    <AlertCircle className="w-5 h-5" />
                    {locStatus?.message}
                </motion.div>
            )}
        </GlassCard>
    );
}
