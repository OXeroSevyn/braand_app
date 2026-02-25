"use client";

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

    const buttonContent = isLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : isClockedIn ? <LogOut className="w-5 h-5" /> : <LogIn className="w-5 h-5" />;
    const buttonText = isLoading ? 'Verifying...' : isClockedIn ? 'Clock Out' : 'Clock In Now';

    const renderClockButton = () => {
        const buttonStyles = isClockedIn ? 'bg-white text-black' : 'bg-neon-green text-black';
        const disabledStyles = (isLoading || isOutOfRange) ? 'opacity-50 cursor-not-allowed grayscale' : '';

        return (
            <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={onClockToggle}
                disabled={isLoading || isOutOfRange}
                className={`relative group px-10 py-5 border-4 border-black font-black uppercase tracking-tighter transition-all duration-200 shadow-[6px_6px_0px_0px_rgba(0,0,0,1)] hover:shadow-[10px_10px_0px_0px_rgba(0,0,0,1)] active:shadow-none active:translate-x-[4px] active:translate-y-[4px] flex items-center gap-3 ${buttonStyles} ${disabledStyles}`}
            >
                {buttonContent}
                <span className="relative z-10">{buttonText}</span>
            </motion.button>
        );
    };

    return (
        <GlassCard className="p-8 overflow-hidden relative border-black bg-white">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-8">
                <div>
                    <motion.div
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        className="flex items-center gap-3 mb-4"
                    >
                        <span className="px-5 py-2 border-4 border-black bg-neon-green text-xs font-black uppercase tracking-[0.2em] shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] text-black">
                            LIVE TRACKING
                        </span>
                        {locStatus && (
                            <span className={`flex items-center gap-2 text-xs font-black uppercase tracking-widest p-2 border-4 border-black ${locStatus.isInRange ? 'bg-emerald-400' : 'bg-rose-400'} shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] text-black`}>
                                <MapPin className="w-4 h-4" />
                                {locStatus.isInRange ? 'In Range' : 'Out of Range'}
                            </span>
                        )}
                    </motion.div>

                    <h1 className="text-4xl md:text-6xl font-black text-black tracking-tighter mb-4 uppercase italic leading-none">
                        {isClockedIn ? "Session Active" : "Time Tracker"}
                    </h1>
                    <p className="text-black font-black text-xl border-b-8 border-black pb-1 inline-block uppercase italic">
                        {formattedTime} <span className="text-black/40">//</span> {formattedDate}
                    </p>
                </div>

                <div className="flex items-center gap-6">
                    {isClockedIn && clockInTime && (
                        <div className="text-right hidden sm:block border-l-8 border-black pl-8">
                            <p className="text-black/60 text-xs font-black uppercase tracking-widest mb-1">Started at</p>
                            <p className="text-3xl font-black text-black italic">
                                {clockInTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                            </p>
                        </div>
                    )}

                    {renderClockButton()}
                </div>
            </div>

            {isOutOfRange && (
                <motion.p
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    className="mt-10 text-black text-sm font-black flex items-center gap-3 bg-rose-400 p-6 border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] uppercase italic"
                >
                    <AlertCircle className="w-6 h-6" />
                    {locStatus?.message}
                </motion.p>
            )}
        </GlassCard>
    );
}
