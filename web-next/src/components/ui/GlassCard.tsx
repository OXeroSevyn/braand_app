"use client";

import { motion } from "framer-motion";
import { cn } from "@/lib/utils";
import { ReactNode } from "react";

interface GlassCardProps {
    children: ReactNode;
    className?: string;
    variant?: "elevated" | "filled" | "outlined";
    hover?: boolean;
    delay?: number;
}

export const GlassCard = ({
    children,
    className,
    variant = "filled",
    hover = true,
    delay = 0
}: GlassCardProps) => {
    return (
        <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay, ease: [0.2, 0, 0, 1] }}
            className={cn(
                "m3-card relative overflow-hidden group/m3card",
                variant === "elevated" && "m3-card-elevated",
                variant === "outlined" && "m3-card-outline",
                hover && "hover:bg-surface-container-high cursor-pointer",
                className
            )}
        >
            <div className="relative z-10">
                {children}
            </div>
        </motion.div>
    );
};

