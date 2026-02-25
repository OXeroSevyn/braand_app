"use client";

import { GlassCard } from "@/components/ui/GlassCard";
import { Search, Filter } from "lucide-react";

export default function EmployeesPage() {
    return (
        <div className="min-h-screen p-6 lg:p-10">
            <header className="flex justify-between items-center mb-12">
                <div>
                    <h1 className="text-4xl md:text-5xl font-black tracking-tighter uppercase text-white">
                        TEAM
                    </h1>
                    <p className="text-[10px] font-bold text-neon-green uppercase tracking-[0.3em]">Employee Directory</p>
                </div>
                <div className="flex gap-4">
                    <button className="p-4 border-2 border-black bg-dark-grey text-white"><Search className="w-5 h-5" /></button>
                    <button className="p-4 border-2 border-black bg-dark-grey text-white"><Filter className="w-5 h-5" /></button>
                </div>
            </header>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {[
                    { name: "Mayank Aggarwal", dept: "Marketing", role: "Manager" },
                    { name: "Tester 01", dept: "Gaming", role: "QA" },
                    { name: "Ankush Sharma", dept: "Video editor", role: "Senior" },
                    { name: "Soumik Mallick", dept: "Design", role: "Lead" },
                    { name: "laksh verma", dept: "Design", role: "Junior" }
                ].map((emp) => (
                    <GlassCard key={emp.name} className="bg-dark-grey border-black group">
                        <div className="flex items-center gap-6">
                            <div className="w-20 h-20 rounded-full border-4 border-neon-green bg-black flex items-center justify-center text-3xl font-black text-neon-green group-hover:bg-neon-green group-hover:text-black transition-colors">
                                {emp.name.charAt(0)}
                            </div>
                            <div>
                                <h3 className="text-xl font-black text-white uppercase">{emp.name}</h3>
                                <p className="text-sm font-bold text-neon-green uppercase tracking-widest">{emp.dept}</p>
                                <p className="text-[10px] font-bold text-white/40 uppercase mt-2">{emp.role}</p>
                            </div>
                        </div>
                    </GlassCard>
                ))}
            </div>
        </div>
    );
}
