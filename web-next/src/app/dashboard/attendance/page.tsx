"use client";

import { useEffect, useState, useCallback } from "react";
import { useAuth } from "@/context/AuthContext";
import { AttendanceHeader } from "@/components/dashboard/attendance/AttendanceHeader";
import { BentoStatsGrid } from "@/components/dashboard/attendance/BentoStatsGrid";
import { attendanceService, AttendanceRecord, AttendanceType, AttendanceStats } from "@/lib/services/attendanceService";
import { motion, AnimatePresence } from "framer-motion";
import { Loader2, Calendar as CalendarIcon, History } from "lucide-react";
import { GlassCard } from "@/components/ui/GlassCard";

export default function AttendancePage() {
    const { user } = useAuth();
    const [records, setRecords] = useState<AttendanceRecord[]>([]);
    const [stats, setStats] = useState<AttendanceStats | null>(null);
    const [loading, setLoading] = useState(true);
    const [actionLoading, setActionLoading] = useState(false);
    const [isClockedIn, setIsClockedIn] = useState(false);
    const [clockInTime, setClockInTime] = useState<Date | null>(null);

    const loadData = useCallback(async () => {
        if (!user) return;
        setLoading(true);
        try {
            const userRecords = await attendanceService.getUserRecords(user.id);
            const userStats = await attendanceService.getAttendanceStats(user.id);

            setRecords(userRecords);
            setStats(userStats);
            determineStatus(userRecords);
        } catch (err) {
            console.error("Failed to load attendance data", err);
        } finally {
            setLoading(false);
        }
    }, [user]);

    const determineStatus = (records: AttendanceRecord[]) => {
        if (records.length === 0) {
            setIsClockedIn(false);
            setClockInTime(null);
            return;
        }

        const latest = records[0];
        if (latest.type === AttendanceType.CLOCK_IN || latest.type === AttendanceType.BREAK_END) {
            const latestTime = new Date(latest.timestamp);
            const now = new Date();

            if (latestTime.toDateString() === now.toDateString()) {
                setIsClockedIn(true);
                setClockInTime(latestTime);
            } else {
                setIsClockedIn(false);
                setClockInTime(null);
            }
        } else {
            setIsClockedIn(false);
            setClockInTime(null);
        }
    };

    useEffect(() => {
        loadData();
    }, [loadData]);

    const handleClockToggle = async () => {
        if (!user) return;
        setActionLoading(true);
        const type = isClockedIn ? AttendanceType.CLOCK_OUT : AttendanceType.CLOCK_IN;

        try {
            const result = await attendanceService.logAttendance(user.id, type);
            if (result.success) {
                await loadData();
            } else {
                alert(result.error || "Action failed");
            }
        } catch (err) {
            console.error("Clock toggle error", err);
        } finally {
            setActionLoading(false);
        }
    };

    if (loading) {
        return (
            <div className="flex h-[80vh] items-center justify-center">
                <Loader2 className="w-10 h-10 animate-spin text-aura-1" />
            </div>
        );
    }

    return (
        <div className="max-w-7xl mx-auto px-4 py-8 space-y-8">
            <AttendanceHeader
                isClockedIn={isClockedIn}
                clockInTime={clockInTime}
                onClockToggle={handleClockToggle}
                isLoading={actionLoading}
            />

            <BentoStatsGrid stats={stats} />

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Simplified Calendar Placeholder */}
                <div className="lg:col-span-2 space-y-6">
                    <div className="flex items-center justify-between">
                        <h2 className="text-2xl font-bold text-white flex items-center gap-3">
                            <CalendarIcon className="w-6 h-6 text-aura-1" />
                            Work Calendar
                        </h2>
                    </div>
                    <GlassCard className="aspect-video flex items-center justify-center border-dashed">
                        <p className="text-white/30 font-mono uppercase tracking-widest text-sm">Interactive Calendar Coming Soon</p>
                    </GlassCard>
                </div>

                {/* History/Timeline Sidebar */}
                <div className="space-y-6">
                    <h2 className="text-2xl font-bold text-white flex items-center gap-3">
                        <History className="w-6 h-6 text-aura-2" />
                        Activity
                    </h2>
                    <div className="space-y-4">
                        <AnimatePresence>
                            {records.slice(0, 5).map((record, index) => (
                                <motion.div
                                    key={record.id || index}
                                    initial={{ opacity: 0, x: 20 }}
                                    animate={{ opacity: 1, x: 0 }}
                                    transition={{ delay: index * 0.1 }}
                                >
                                    <GlassCard className="p-4 flex items-center justify-between border-white/5">
                                        <div className="flex items-center gap-4">
                                            <div className={`w-2 h-2 rounded-full ${record.type.includes('IN') ? 'bg-emerald-400' : 'bg-rose-400'}`} />
                                            <div>
                                                <p className="text-white font-medium text-sm">
                                                    {record.type.replace('AttendanceType.', '').replace('_', ' ')}
                                                </p>
                                                <p className="text-white/30 text-xs font-mono">
                                                    {new Date(record.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                </p>
                                            </div>
                                        </div>
                                        <div className="text-right">
                                            <p className="text-white/20 text-[10px] font-mono uppercase tracking-tighter">
                                                {new Date(record.timestamp).toLocaleDateString([], { month: 'short', day: 'numeric' })}
                                            </p>
                                        </div>
                                    </GlassCard>
                                </motion.div>
                            ))}
                        </AnimatePresence>
                    </div>
                </div>
            </div>
        </div>
    );
}
