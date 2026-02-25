"use client";

import { GlassCard } from "@/components/ui/GlassCard";
import { useAuth } from "@/context/AuthContext";
import { attendanceService } from "@/lib/services/attendanceService";
import { motion } from "framer-motion";
import { Calendar as CalendarIcon, Clock, MapPin, AlertCircle, Users } from "lucide-react";
import { useEffect, useState, useCallback } from "react";
import { AttendanceHeader } from "@/components/dashboard/attendance/AttendanceHeader";

export default function AttendancePage() {
    const { user } = useAuth();
    const [stats, setStats] = useState({ present: 19, late: 19, avgHrs: 7.2 });
    const [isClockedIn, setIsClockedIn] = useState(false);
    const [clockInTime, setClockInTime] = useState<Date | null>(null);
    const [isLoading, setIsLoading] = useState(false);

    const loadAttendanceStatus = useCallback(async () => {
        if (!user) return;
        try {
            const session = await attendanceService.getCurrentSession(user.id);
            if (session?.[0]) {
                setIsClockedIn(true);
                setClockInTime(new Date(session[0].clock_in));
            }
        } catch (err) {
            console.error("Failed to load attendance", err);
        }
    }, [user]);

    useEffect(() => {
        loadAttendanceStatus();
    }, [loadAttendanceStatus]);

    const handleClockToggle = async () => {
        if (!user) return;
        setIsLoading(true);
        try {
            if (isClockedIn) {
                await attendanceService.clockOut(user.id);
                setIsClockedIn(false);
                setClockInTime(null);
            } else {
                await attendanceService.clockIn(user.id);
                setIsClockedIn(true);
                setClockInTime(new Date());
            }
        } catch (err) {
            console.error("Action failed", err);
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="min-h-screen p-6 lg:p-10 space-y-10">
            {/* Header Section */}
            <header className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
                <div>
                    <h1 className="text-4xl md:text-5xl font-black tracking-tighter uppercase text-white">
                        ATTENDANCE
                    </h1>
                    <p className="text-[10px] font-bold text-white/40 uppercase tracking-[0.3em]">
                        {new Date().toLocaleDateString('en-US', { weekday: 'long', day: 'numeric', month: 'long' })}
                    </p>
                </div>

                <div className="flex items-center gap-2">
                    <button className="p-2 w-10 h-10 border-2 border-black bg-dark-grey text-white/40 flex items-center justify-center">
                        <Users className="w-5 h-5" />
                    </button>
                </div>
            </header>

            {/* Attendance Header Component (With Clock Button) */}
            <AttendanceHeader
                isClockedIn={isClockedIn}
                clockInTime={clockInTime}
                onClockToggle={handleClockToggle}
                isLoading={isLoading}
            />

            {/* KPI Cards (Matching Reference App Styles) */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <GlassCard className="bg-indigo-500 border-black p-0 overflow-hidden">
                    <div className="p-6">
                        <div className="flex justify-between items-start mb-10">
                            <CalendarIcon className="w-5 h-5 text-white/60" />
                            <span className="text-[10px] font-black text-white/40 uppercase">Days</span>
                        </div>
                        <p className="text-6xl font-black text-white">19</p>
                        <p className="text-xs font-black text-white/60 uppercase mt-2">Present</p>
                    </div>
                </GlassCard>

                <GlassCard className="bg-orange-500 border-black p-0 overflow-hidden">
                    <div className="p-6">
                        <div className="flex justify-between items-start mb-10">
                            <AlertCircle className="w-5 h-5 text-black/40" />
                        </div>
                        <div className="flex items-baseline gap-2">
                            <p className="text-6xl font-black text-black">19</p>
                            <span className="text-xs font-black text-black/60 uppercase">Late</span>
                        </div>
                    </div>
                </GlassCard>

                <GlassCard className="bg-emerald-500 border-black p-0 overflow-hidden">
                    <div className="p-6">
                        <div className="flex justify-between items-start mb-10">
                            <Clock className="w-5 h-5 text-black/40" />
                        </div>
                        <div className="flex items-baseline gap-2">
                            <p className="text-6xl font-black text-black">7.2</p>
                            <span className="text-xs font-black text-black/60 uppercase">Avg Hrs</span>
                        </div>
                    </div>
                </GlassCard>
            </div>

            {/* Month Header & Calendar Placeholder */}
            <div>
                <div className="flex items-center justify-between mb-8">
                    <button className="p-2 border-2 border-black bg-dark-grey text-white"><Clock className="w-4 h-4 rotate-180" /></button>
                    <h2 className="text-2xl font-black text-white uppercase italic tracking-widest">FEBRUARY 2026</h2>
                    <button className="p-2 border-2 border-black bg-dark-grey text-white"><Clock className="w-4 h-4" /></button>
                </div>

                <GlassCard className="bg-white/5 border-white/10 p-10 h-96 flex items-center justify-center">
                    <p className="text-white/20 font-black uppercase italic tracking-widest">Calendar Sync Active</p>
                </GlassCard>
            </div>
        </div>
    );
}
