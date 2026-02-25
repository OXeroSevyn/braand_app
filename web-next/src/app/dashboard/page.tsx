"use client";

import { GlassCard as M3Card } from "@/components/ui/GlassCard";
import {
    Zap,
    Coffee,
    Settings,
    Users,
    Bell,
    ArrowUpRight,
    Search
} from "lucide-react";

export default function DashboardPage() {
    return (
        <div className="min-h-screen pr-8 py-8 bg-background text-foreground transition-all duration-500">
            {/* Top Bar / Search */}
            <div className="flex items-center justify-between mb-10 px-4">
                <div className="relative group flex-1 max-w-md">
                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-on-surface-variant transition-colors group-focus-within:text-primary" />
                    <input
                        type="text"
                        placeholder="Search operations..."
                        className="w-full h-12 pl-12 pr-4 bg-surface-container rounded-full border border-white/5 focus:outline-none focus:border-primary/50 text-sm transition-all"
                    />
                </div>

                <div className="flex items-center gap-2">
                    {[Bell, Settings].map((Icon, i) => (
                        <button key={i} className="w-12 h-12 rounded-full flex items-center justify-center hover:bg-surface-variant transition-all text-on-surface-variant hover:text-white">
                            <Icon className="w-5 h-5" />
                        </button>
                    ))}
                </div>
            </div>

            {/* Header Section */}
            <header className="mb-12 px-4">
                <div className="flex flex-col gap-1">
                    <p className="text-xs font-bold text-primary uppercase tracking-[0.3em]">Command Center</p>
                    <h1 className="text-5xl font-black tracking-tight text-white leading-tight">
                        OPERATIONAL <br />
                        <span className="text-primary italic">INTELLIGENCE</span>
                    </h1>
                </div>
            </header>

            {/* KPI Cards - M3 Elevated */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12 px-2">
                <M3Card variant="elevated" className="h-[220px] flex flex-col justify-between p-8 border-none bg-surface-container-high relative overflow-hidden group">
                    <div className="absolute -right-4 -top-4 w-32 h-32 bg-white/5 rounded-full blur-3xl group-hover:bg-primary/10 transition-all" />
                    <div className="flex justify-between items-start relative z-10">
                        <div className="p-3 rounded-2xl bg-white/5">
                            <Users className="w-6 h-6 text-white/40" />
                        </div>
                        <ArrowUpRight className="w-5 h-5 text-white/20 group-hover:text-primary transition-colors" />
                    </div>
                    <div>
                        <p className="text-xs font-bold text-on-surface-variant uppercase tracking-widest mb-1">Total Payroll</p>
                        <p className="text-6xl font-black text-white">11</p>
                    </div>
                </M3Card>

                <M3Card variant="elevated" className="h-[220px] flex flex-col justify-between p-8 border-none bg-primary text-black relative overflow-hidden group">
                    <div className="absolute -right-4 -top-4 w-32 h-32 bg-black/5 rounded-full blur-3xl group-hover:bg-black/10 transition-all" />
                    <div className="flex justify-between items-start relative z-10">
                        <div className="p-3 rounded-2xl bg-black/10">
                            <Zap className="w-6 h-6 text-black" />
                        </div>
                        <ArrowUpRight className="w-5 h-5 text-black/40" />
                    </div>
                    <div>
                        <p className="text-xs font-bold text-black/60 uppercase tracking-widest mb-1">Deployed Now</p>
                        <p className="text-6xl font-black text-black">0</p>
                    </div>
                </M3Card>

                <M3Card variant="elevated" className="h-[220px] flex flex-col justify-between p-8 border-none bg-surface-container-high relative overflow-hidden group">
                    <div className="absolute -right-4 -top-4 w-32 h-32 bg-white/5 rounded-full blur-3xl group-hover:bg-primary/10 transition-all" />
                    <div className="flex justify-between items-start relative z-10">
                        <div className="p-3 rounded-2xl bg-white/5">
                            <Coffee className="w-6 h-6 text-white/40" />
                        </div>
                        <ArrowUpRight className="w-5 h-5 text-white/20 group-hover:text-primary transition-colors" />
                    </div>
                    <div>
                        <p className="text-xs font-bold text-on-surface-variant uppercase tracking-widest mb-1">In Rest Mode</p>
                        <p className="text-6xl font-black text-white">0</p>
                    </div>
                </M3Card>
            </div>

            {/* Personnel List - Tonal Cards */}
            <div className="px-2">
                <div className="flex items-center justify-between mb-8 px-2">
                    <h3 className="text-lg font-bold text-white tracking-tight">Active Deployment</h3>
                    <button className="text-xs font-bold text-primary uppercase tracking-widest hover:underline">View All</button>
                </div>

                <div className="grid grid-cols-1 gap-3">
                    {[
                        { id: 1, name: "Mayank Aggarwal", dept: "Marketing", status: "Offline", initials: "MA" },
                        { id: 2, name: "Tester 01", dept: "Gaming", status: "Offline", initials: "T1" },
                        { id: 3, name: "Ankush Sharma", dept: "Video editor", status: "Offline", initials: "AS" },
                        { id: 4, name: "Soumik Mallick", dept: "Design", status: "Offline", initials: "SM" },
                    ].map((emp) => (
                        <M3Card key={emp.id} variant="filled" className="px-6 py-4 border-none bg-surface-container/40 hover:bg-surface-container transition-all rounded-[24px]">
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-4">
                                    <div className="w-12 h-12 rounded-2xl bg-surface-variant flex items-center justify-center text-sm font-bold text-white">
                                        {emp.initials}
                                    </div>
                                    <div>
                                        <p className="text-base font-bold text-white">{emp.name}</p>
                                        <p className="text-xs text-on-surface-variant">{emp.dept}</p>
                                    </div>
                                </div>
                                <div className="flex items-center gap-4">
                                    <span className="px-4 py-1.5 rounded-full bg-white/5 text-[10px] font-bold text-on-surface-variant uppercase tracking-widest">
                                        {emp.status}
                                    </span>
                                    <div className="w-8 h-8 rounded-full flex items-center justify-center hover:bg-white/5 text-on-surface-variant">
                                        <ArrowUpRight className="w-4 h-4" />
                                    </div>
                                </div>
                            </div>
                        </M3Card>
                    ))}
                </div>
            </div>
        </div>
    );
}

