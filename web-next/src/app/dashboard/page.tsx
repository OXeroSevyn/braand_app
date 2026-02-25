"use client";

import { GlassCard } from "@/components/ui/GlassCard";
import { useAuth } from "@/context/AuthContext";
import { taskService, Task } from "@/lib/services";
import { motion } from "framer-motion";
import {
    MapPin,
    MapPin,
    Clock,
    Zap,
    Coffee,
    User,
    Settings,
    Users
} from "lucide-react";
import { useEffect, useState, useCallback } from "react";
import Image from "next/image";
import Link from "next/link";

export default function DashboardPage() {
    const { user, signOut } = useAuth();
    const [tasks, setTasks] = useState<Task[]>([]);
    const [loading, setLoading] = useState(true);

    const loadData = useCallback(async () => {
        if (!user) return;
        setLoading(true);
        try {
            const userTasks = await taskService.getUserTasks(user.id);
            setTasks(userTasks);
        } catch (err) {
            console.error("Failed to load dashboard data", err);
        } finally {
            setLoading(false);
        }
    }, [user]);

    useEffect(() => {
        if (user) {
            loadData();
        }
    }, [user, loadData]);

    const toggleTask = async (taskId: string, currentStatus: boolean) => {
        try {
            await taskService.toggleTask(taskId, !currentStatus);
            setTasks(tasks.map(t => t.id === taskId ? { ...t, is_completed: !currentStatus } : t));
        } catch (err) {
            console.error("Failed to update task", err);
        }
    };

    const completedCount = tasks.filter(t => t.is_completed).length;
    const completionRate = tasks.length > 0 ? (completedCount / tasks.length) * 100 : 0;

    return (
        <div className="min-h-screen p-6 lg:p-10 bg-background">
            {/* Header Section */}
            <header className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-12">
                <div>
                    <h1 className="text-4xl md:text-5xl font-black tracking-tighter uppercase text-white">
                        GLOBAL <span className="text-neon-green">OPS</span>
                    </h1>
                    <p className="text-[10px] font-bold text-white/40 uppercase tracking-[0.3em]">Admin Dashboard</p>
                </div>

                <div className="flex items-center gap-4">
                    <button className="p-2 text-white/60 hover:text-neon-green transition-colors"><MapPin className="w-5 h-5" /></button>
                    <button className="p-2 text-white/60 hover:text-neon-green transition-colors"><Clock className="w-5 h-5" /></button>
                    <button className="p-2 text-white/60 hover:text-neon-green transition-colors"><Bell className="w-5 h-5" /></button>
                    <button className="p-2 text-white/60 hover:text-neon-green transition-colors"><User className="w-5 h-5" /></button>
                    <button className="p-2 text-white/60 hover:text-neon-green transition-colors"><Settings className="w-5 h-5" /></button>
                </div>
            </header>

            {/* KPI Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
                <GlassCard className="bg-dark-grey border-black">
                    <div className="flex justify-between items-center">
                        <div>
                            <Users className="w-5 h-5 text-white/40 mb-4" />
                            <p className="text-[8px] font-black text-white/40 uppercase tracking-widest">Total Staff</p>
                        </div>
                        <p className="text-6xl font-black text-white tabular-nums">11</p>
                    </div>
                </GlassCard>

                <GlassCard className="bg-neon-green border-black">
                    <div className="flex justify-between items-center">
                        <div>
                            <Zap className="w-5 h-5 text-black mb-4" />
                            <p className="text-[8px] font-black text-black uppercase tracking-widest">Online Now</p>
                        </div>
                        <p className="text-6xl font-black text-black tabular-nums">0</p>
                    </div>
                </GlassCard>

                <GlassCard className="bg-dark-grey border-black">
                    <div className="flex justify-between items-center">
                        <div>
                            <Coffee className="w-5 h-5 text-white/40 mb-4" />
                            <p className="text-[8px] font-black text-white/40 uppercase tracking-widest">On Break</p>
                        </div>
                        <p className="text-6xl font-black text-white tabular-nums">0</p>
                    </div>
                </GlassCard>
            </div>

            {/* Workforce Status Section */}
            <div className="space-y-6">
                <div className="flex items-center justify-between mb-6">
                    <h3 className="text-sm font-black text-white uppercase tracking-widest">Workforce Status</h3>
                    <div className="h-0.5 flex-1 bg-white/5 mx-6" />
                </div>

                <div className="grid grid-cols-1 gap-4">
                    {[
                        { name: "Mayank Aggarwal", dept: "Marketing", status: "OFFLINE" },
                        { name: "Tester 01", dept: "Gaming", status: "OFFLINE" },
                        { name: "Ankush Sharma", dept: "Video editor", status: "OFFLINE" },
                        { name: "Soumik Mallick", dept: "Design", status: "OFFLINE" },
                        { name: "laksh verma", dept: "Video editing & Designing", status: "OFFLINE" },
                        { name: "Muskan Khatoon", dept: "Social Media Manager", status: "OFFLINE" }
                    ].map((emp, i) => (
                        <GlassCard key={i} className="py-4 bg-transparent border-t-2 border-x-0 border-b-0 border-white/5 shadow-none hover:bg-white/5 transition-colors rounded-none group/item">
                            <div className="flex flex-col md:flex-row justify-between items-center gap-4">
                                <div className="flex items-center gap-4 w-full md:w-auto">
                                    <div className="w-10 h-10 rounded-full bg-neon-green/20 border-2 border-neon-green flex items-center justify-center text-xs font-black text-neon-green group-hover/item:bg-neon-green group-hover/item:text-black transition-colors">
                                        {emp.name.charAt(0)}
                                    </div>
                                    <div>
                                        <p className="text-sm font-black text-white">{emp.name}</p>
                                        <p className="text-[10px] font-bold text-white/40 uppercase">{emp.dept}</p>
                                    </div>
                                </div>
                                <div className="w-full md:w-auto flex justify-end">
                                    <span className="px-3 py-1 border-2 border-black bg-dark-grey text-[8px] font-black text-white/40 uppercase tracking-widest">
                                        {emp.status}
                                    </span>
                                </div>
                            </div>
                        </GlassCard>
                    ))}
                </div>
            </div>
        </div>
    );
}
