"use client";

import { GlassCard } from "@/components/ui/GlassCard";
import { CheckSquare, Clock } from "lucide-react";

export default function TasksPage() {
    return (
        <div className="min-h-screen p-6 lg:p-10">
            <header className="flex justify-between items-center mb-12">
                <div>
                    <h1 className="text-4xl md:text-5xl font-black tracking-tighter uppercase text-white">
                        REPORTS
                    </h1>
                    <p className="text-[10px] font-bold text-neon-green uppercase tracking-[0.3em]">Task Reports</p>
                </div>
                <button className="px-6 py-4 border-4 border-black bg-neon-green text-black font-black uppercase tracking-widest shadow-[6px_6px_0px_0px_rgba(0,0,0,1)] active:shadow-none active:translate-x-1 active:translate-y-1 transition-all">
                    NEW REPORT
                </button>
            </header>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                <GlassCard className="bg-dark-grey border-black">
                    <h3 className="text-xl font-black text-white uppercase mb-6 flex items-center gap-3">
                        <Clock className="w-5 h-5 text-neon-green" />
                        Active Tasks
                    </h3>
                    <div className="space-y-4">
                        {[1, 2, 3].map(i => (
                            <div key={i} className="p-4 border-b border-white/5 flex items-center justify-between group cursor-pointer hover:bg-white/5 transition-colors">
                                <span className="text-sm font-bold text-white/60 group-hover:text-white">Project Protocol Alpha-{i}</span>
                                <span className="text-[10px] font-black text-neon-green uppercase tracking-widest">In Progress</span>
                            </div>
                        ))}
                    </div>
                </GlassCard>

                <GlassCard className="bg-dark-grey border-black">
                    <h3 className="text-xl font-black text-white uppercase mb-6 flex items-center gap-3">
                        <CheckSquare className="w-5 h-5 text-neon-green" />
                        Completion Stats
                    </h3>
                    <div className="flex items-center justify-center h-48">
                        <p className="text-white/20 font-black uppercase italic tracking-widest">Analytics syncing...</p>
                    </div>
                </GlassCard>
            </div>
        </div>
    );
}
