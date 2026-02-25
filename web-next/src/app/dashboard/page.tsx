"use client";

import { GlassCard } from "@/components/ui/GlassCard";
import { useAuth } from "@/context/AuthContext";
import { taskService, Task } from "@/lib/services";
import { motion } from "framer-motion";
import {
    FileText,
    Bell,
    Search,
    LogOut,
    CheckCircle2,
    Circle,
    BellOff
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
        <div className="min-h-screen p-6 md:p-12 text-black font-sans selection:bg-neon-green/30">
            {/* Navigation Bar */}
            <nav className="flex items-center justify-between mb-16 border-b-8 border-black pb-8">
                <div className="flex items-center gap-8">
                    <h2 className="text-2xl font-black tracking-tighter uppercase">Braand</h2>
                    <div className="hidden md:flex items-center gap-6 text-sm font-medium text-foreground/40">
                        <Link href="/dashboard" className="text-foreground transition-colors">Overview</Link>
                        <Link href="/dashboard/attendance" className="hover:text-foreground transition-colors">Attendance</Link>
                        <button className="hover:text-foreground transition-colors">Analytics</button>
                        <button className="hover:text-foreground transition-colors">Settings</button>
                    </div>
                </div>

                <div className="flex items-center gap-4">
                    <div className="hidden sm:flex items-center gap-2 px-4 py-2 rounded-full glass text-xs font-medium text-foreground/40">
                        <Search className="w-3 h-3" />
                        <span>Search anything...</span>
                    </div>
                    <button className="p-3 rounded-full glass hover:bg-white/20 transition-all text-foreground/40 hover:text-foreground">
                        <Bell className="w-4 h-4" />
                    </button>
                    <button
                        onClick={() => signOut()}
                        className="p-3 rounded-full glass hover:bg-aura-2/20 transition-all text-foreground/40 hover:text-aura-2"
                    >
                        <LogOut className="w-4 h-4" />
                    </button>
                    <div className="relative w-10 h-10 rounded-full bg-gradient-to-br from-aura-1 to-aura-2 overflow-hidden border border-white/20">
                        {user?.avatar && (
                            <Image
                                src={user.avatar}
                                alt={user.name}
                                fill
                                className="object-cover"
                            />
                        )}
                    </div>
                </div>
            </nav>

            {/* Main Content */}
            <main className="max-w-7xl mx-auto">
                <header className="mb-12 space-y-2 border-l-8 border-black pl-8 bg-neon-green/10 py-4">
                    <h1 className="text-4xl md:text-6xl font-black tracking-tighter uppercase">HELL-O, {user?.name?.split(' ')[0]}</h1>
                    <p className="text-xl text-black font-bold uppercase italic">Today&apos;s workspace mission status.</p>
                </header>

                <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
                    {/* Work Progress Card */}
                    <GlassCard className="md:col-span-2 flex flex-col justify-between bg-white" delay={0.1}>
                        <div>
                            <span className="text-[12px] uppercase tracking-widest text-black font-black mb-4 block bg-neon-green inline-block px-2">Performance</span>
                            <h3 className="text-5xl font-black mb-2 uppercase tracking-tighter italic">Mission Progress</h3>
                            <p className="text-black font-bold text-sm max-w-xs">
                                Completed {completedCount}/{tasks.length} objectives.
                                {completionRate === 100 ? " MISSION COMPLETE." : " KEEP PUSHING."}
                            </p>
                        </div>

                        <div className="space-y-6">
                            <div className="flex items-end justify-between">
                                <span className="text-6xl font-black">{Math.round(completionRate)}%</span>
                                <span className="text-sm font-medium text-foreground/20 uppercase tracking-widest">Efficiency</span>
                            </div>
                            <div className="h-4 w-full bg-white/5 rounded-full overflow-hidden">
                                <motion.div
                                    initial={{ width: 0 }}
                                    animate={{ width: `${completionRate}%` }}
                                    transition={{ duration: 1, ease: "easeOut" }}
                                    className="h-full bg-gradient-to-r from-aura-1 to-aura-2"
                                />
                            </div>
                        </div>
                    </GlassCard>

                    {/* User Profile Info */}
                    <GlassCard className="md:col-span-2" delay={0.2}>
                        <div className="flex items-start justify-between">
                            <div className="space-y-1">
                                <h3 className="text-xl font-bold">{user?.department} Team</h3>
                                <p className="text-sm text-foreground/40">Role: <span className="text-aura-1 font-medium">{user?.role}</span></p>
                                <div className="inline-flex items-center gap-2 mt-2 px-2 py-1 rounded-lg bg-green-500/10 text-green-500 text-[10px] uppercase font-bold tracking-wider">
                                    Status: {user?.status}
                                </div>
                            </div>
                            <div className="p-3 rounded-2xl bg-aura-1/20 text-aura-1">
                                <FileText className="w-5 h-5" />
                            </div>
                        </div>
                    </GlassCard>

                    {/* Real Tasks List */}
                    <GlassCard delay={0.3} className="overflow-hidden flex flex-col">
                        <h3 className="text-xl font-bold mb-4">Focus Tasks</h3>
                        <div className="flex-1 overflow-y-auto space-y-4 pr-2 custom-scrollbar">
                            {loading ? (
                                <div className="space-y-4">
                                    {[1, 2, 3].map(i => <div key={i} className="h-10 bg-white/5 animate-pulse rounded-xl" />)}
                                </div>
                            ) : tasks.length > 0 ? (
                                tasks.map((task) => (
                                    <button
                                        key={task.id}
                                        onClick={() => toggleTask(task.id, task.is_completed)}
                                        className="w-full flex items-center gap-3 text-sm text-foreground/60 hover:text-foreground transition-colors text-left group"
                                    >
                                        {task.is_completed ? (
                                            <CheckCircle2 className="w-5 h-5 text-aura-1 shrink-0" />
                                        ) : (
                                            <Circle className="w-5 h-5 text-foreground/10 shrink-0 group-hover:text-aura-1/50" />
                                        )}
                                        <span className={task.is_completed ? "line-through opacity-40" : ""}>{task.title}</span>
                                    </button>
                                ))
                            ) : (
                                <p className="text-xs text-foreground/20 italic">No tasks for today.</p>
                            )}
                        </div>
                    </GlassCard>

                    <GlassCard className="bg-aura-1/5 border-aura-1/20" delay={0.4}>
                        <h3 className="text-xl font-bold mb-1">Messages</h3>
                        <p className="text-3xl font-black mt-2">5</p>
                        <span className="text-xs text-aura-1 font-bold">Unread notifications</span>
                    </GlassCard>
                </div>
            </main>

            <style jsx>{`
        .custom-scrollbar::-webkit-scrollbar { width: 4px; }
        .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.1); border-radius: 10px; }
      `}</style>
        </div>
    );
}
