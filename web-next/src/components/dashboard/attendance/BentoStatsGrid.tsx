import { motion } from "framer-motion";
import { GlassCard } from "../../ui/GlassCard";
import { Clock, Calendar, AlertCircle, PieChart } from "lucide-react";
import { AttendanceStats } from "../../../lib/services/attendanceService";

const StatItem = ({ title, value, icon: Icon, colorClass, delay }: {
    readonly title: string;
    readonly value: string | number;
    readonly icon: React.ComponentType<{ className?: string }>;
    readonly colorClass: string;
    readonly delay: number;
}) => (
    <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay }}
    >
        <GlassCard className="h-full flex flex-col justify-between p-6">
            <div className="flex justify-between items-start mb-6">
                <div className={`p-3 border-4 border-black bg-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] ${colorClass}`}>
                    <Icon className="w-6 h-6" />
                </div>
                <span className="text-black font-black text-xs uppercase tracking-widest bg-neon-green px-2 border-2 border-black">STAT</span>
            </div>
            <div>
                <h3 className="text-black/60 text-sm font-black uppercase mb-1">{title}</h3>
                <div className="flex items-baseline gap-2">
                    <span className="text-4xl font-black text-black tracking-tighter italic">{value}</span>
                </div>
            </div>
        </GlassCard>
    </motion.div>
);

export function BentoStatsGrid({ stats }: { readonly stats: AttendanceStats | null }) {
    if (!stats) return null;

    return (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <StatItem
                title="Present Days"
                value={stats.presentDays}
                icon={Calendar}
                colorClass="text-emerald-400"
                delay={0.1}
            />
            <StatItem
                title="Late Marks"
                value={stats.lateDays}
                icon={AlertCircle}
                colorClass="text-amber-400"
                delay={0.2}
            />
            <StatItem
                title="Avg. Work Hours"
                value={stats.averageHours.toFixed(1)}
                icon={Clock}
                colorClass="text-aura-1"
                delay={0.3}
            />
            <StatItem
                title="Total Working"
                value={stats.totalWorkingDays}
                icon={PieChart}
                colorClass="text-aura-2"
                delay={0.4}
            />
        </div>
    );
}
