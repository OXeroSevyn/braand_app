"use client";

import { GlassCard as M3Card } from "@/components/ui/GlassCard";
import { useAuth } from "@/context/AuthContext";
import { attendanceService, AttendanceType } from "@/lib/services/attendanceService";
import { supabase } from "@/lib/supabase";
import { Calendar as CalendarIcon, Clock, AlertCircle, Users, ChevronLeft, ChevronRight, History } from "lucide-react";
import { useEffect, useState, useCallback } from "react";
import { AttendanceHeader } from "@/components/dashboard/attendance/AttendanceHeader";

export default function AttendancePage() {
    const { user } = useAuth();
    const [isClockedIn, setIsClockedIn] = useState(false);
    const [isOnBreak, setIsOnBreak] = useState(false);
    const [clockInTime, setClockInTime] = useState<Date | null>(null);
    const [isLoading, setIsLoading] = useState(false);

    const loadAttendanceStatus = useCallback(async () => {
        if (!user) return;
        try {
            const { data } = await supabase
                .from('attendance_records')
                .select('*')
                .eq('user_id', user.id)
                .order('timestamp', { ascending: false })
                .limit(1);

            if (data?.[0]) {
                const lastRecord = data[0];
                if (lastRecord.type === 'AttendanceType.CLOCK_IN' || lastRecord.type === 'AttendanceType.BREAK_END') {
                    setIsClockedIn(true);
                    setIsOnBreak(false);
                } else if (lastRecord.type === 'AttendanceType.BREAK_START') {
                    setIsClockedIn(true);
                    setIsOnBreak(true);
                } else {
                    setIsClockedIn(false);
                }
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
                await attendanceService.logAttendance(user.id, AttendanceType.CLOCK_OUT);
                setIsClockedIn(false);
                setIsOnBreak(false);
                setClockInTime(null);
            } else {
                await attendanceService.logAttendance(user.id, AttendanceType.CLOCK_IN);
                setIsClockedIn(true);
                setClockInTime(new Date());
            }
        } catch (err) {
            console.error("Action failed", err);
        } finally {
            setIsLoading(false);
        }
    };

    const handleBreakToggle = async () => {
        if (!user || !isClockedIn) return;
        setIsLoading(true);
        try {
            if (isOnBreak) {
                await attendanceService.endBreak(user.id);
                setIsOnBreak(false);
            } else {
                await attendanceService.startBreak(user.id);
                setIsOnBreak(true);
            }
        } catch (err) {
            console.error("Break toggle failed", err);
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="min-h-screen pr-8 py-8 bg-background text-foreground space-y-12">
            {/* Header Section */}
            <header className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 px-4">
                <div>
                    <p className="text-xs font-bold text-primary uppercase tracking-[0.3em] mb-1">Time Intelligence</p>
                    <h1 className="text-5xl font-black tracking-tight text-white uppercase italic leading-none">
                        ATTENDANCE <span className="text-primary cursor-default">.</span>
                    </h1>
                </div>

                <div className="flex items-center gap-2">
                    <button className="w-12 h-12 rounded-full border border-white/5 bg-surface-container flex items-center justify-center text-on-surface-variant hover:bg-surface-variant transition-all">
                        <Users className="w-5 h-5" />
                    </button>
                    <button className="px-6 h-12 rounded-full bg-white/5 border border-white/5 text-xs font-bold text-white uppercase tracking-widest hover:bg-white/10 transition-all">
                        Reports
                    </button>
                </div>
            </header>

            {/* Attendance Header Component (With Clock & Break Buttons) */}
            <div className="px-2">
                <AttendanceHeader
                    isClockedIn={isClockedIn}
                    isOnBreak={isOnBreak}
                    clockInTime={clockInTime}
                    onClockToggle={handleClockToggle}
                    onBreakToggle={handleBreakToggle}
                    isLoading={isLoading}
                />
            </div>

            {/* KPI Cards - M3 Elevated with Tonal Accents */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 px-2">
                <M3Card variant="elevated" className="bg-surface-container-high p-8 border-none relative group overflow-hidden">
                    <div className="absolute top-0 right-0 w-32 h-32 bg-primary/5 rounded-full blur-[40px] group-hover:bg-primary/10 transition-all" />
                    <div className="flex justify-between items-start mb-10 relative z-10">
                        <div className="p-3 rounded-2xl bg-white/5">
                            <CalendarIcon className="w-6 h-6 text-white/40 group-hover:text-primary transition-colors" />
                        </div>
                        <span className="text-[10px] font-black text-on-surface-variant uppercase tracking-widest">MTD PRESENT</span>
                    </div>
                    <p className="text-7xl font-black text-white leading-none mb-2">19</p>
                    <p className="text-[10px] font-bold text-on-surface-variant uppercase tracking-tighter">Day cycle streak: 12</p>
                </M3Card>

                <M3Card variant="elevated" className="bg-surface-container-high p-8 border-none relative group overflow-hidden">
                    <div className="absolute top-0 right-0 w-32 h-32 bg-amber-500/5 rounded-full blur-[40px] group-hover:bg-amber-500/10 transition-all" />
                    <div className="flex justify-between items-start mb-10 relative z-10">
                        <div className="p-3 rounded-2xl bg-amber-500/10">
                            <AlertCircle className="w-6 h-6 text-amber-500" />
                        </div>
                        <span className="text-[10px] font-black text-amber-500/60 uppercase tracking-widest">Exceptions</span>
                    </div>
                    <div className="flex items-baseline gap-3">
                        <p className="text-7xl font-black text-white leading-none">04</p>
                        <span className="text-sm font-black text-amber-500 uppercase italic">LATE</span>
                    </div>
                </M3Card>

                <M3Card variant="elevated" className="bg-surface-container-high p-8 border-none relative group overflow-hidden">
                    <div className="absolute top-0 right-0 w-32 h-32 bg-primary/5 rounded-full blur-[40px] group-hover:bg-primary/10 transition-all" />
                    <div className="flex justify-between items-start mb-10 relative z-10">
                        <div className="p-3 rounded-2xl bg-white/5">
                            <Clock className="w-6 h-6 text-white/40 group-hover:text-primary transition-colors" />
                        </div>
                        <span className="text-[10px] font-black text-on-surface-variant uppercase tracking-widest">Efficiency</span>
                    </div>
                    <div className="flex items-baseline gap-3">
                        <p className="text-7xl font-black text-white leading-none">7.2</p>
                        <span className="text-sm font-black text-primary uppercase italic">AVG HRS</span>
                    </div>
                </M3Card>
            </div>

            {/* History Section */}
            <div className="px-2">
                <div className="flex items-center justify-between mb-8 px-4">
                    <div className="flex items-center gap-4">
                        <button className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center text-white/40 hover:text-white transition-all"><ChevronLeft className="w-5 h-5" /></button>
                        <h2 className="text-2xl font-black text-white uppercase italic tracking-tighter">FEBRUARY 2026</h2>
                        <button className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center text-white/40 hover:text-white transition-all"><ChevronRight className="w-5 h-5" /></button>
                    </div>
                    <button className="flex items-center gap-2 text-xs font-bold text-on-surface-variant uppercase tracking-widest hover:text-primary transition-colors">
                        <History className="w-4 h-4" />
                        Full History
                    </button>
                </div>

                <M3Card variant="filled" className="bg-surface-container/20 border border-white/5 min-h-[320px] flex flex-col items-center justify-center text-center rounded-[32px]">
                    <div className="w-16 h-16 rounded-3xl bg-surface-container flex items-center justify-center mb-6">
                        <CalendarIcon className="w-8 h-8 text-white/5" />
                    </div>
                    <p className="text-white/20 font-black uppercase italic tracking-[0.3em] text-xs">Calendar Projection Syncing</p>
                </M3Card>
            </div>
        </div>
    );
}

