"use client";

import { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AuraBackground } from "@/components/ui/AuraBackground";
import { supabase } from "@/lib/supabase";
import { motion, AnimatePresence } from "framer-motion";
import { Mail, Lock, User } from "lucide-react";
import { useRouter } from "next/navigation";
import type { FormEvent } from "react";

export default function AuthPage() {
    const [isLogin, setIsLogin] = useState(true);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const router = useRouter();

    // Form states
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [name, setName] = useState("");
    const [role, setRole] = useState("Employee");
    const [department, setDepartment] = useState("General");

    const handleSubmit = async (e: FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError(null);

        try {
            if (isLogin) {
                const { error: authError } = await supabase.auth.signInWithPassword({
                    email,
                    password,
                });
                if (authError) throw authError;
                router.push("/dashboard");
            } else {
                const { data, error: signUpError } = await supabase.auth.signUp({
                    email,
                    password,
                    options: {
                        data: {
                            name,
                            role,
                            department,
                        },
                    },
                });
                if (signUpError) throw signUpError;

                if (data.user) {
                    const { error: profileError } = await supabase.from('profiles').insert({
                        id: data.user.id,
                        name,
                        email,
                        role,
                        department,
                        status: 'pending',
                    });
                    if (profileError) console.error("Profile creation error:", profileError);
                }

                setIsLogin(true);
                setError("Success! Please check your email and then login.");
            }
        } catch (err) {
            const message = err instanceof Error ? err.message : "An error occurred";
            setError(message);
        } finally {
            setLoading(false);
        }
    };

    const handleGoogleSignIn = async () => {
        await supabase.auth.signInWithOAuth({
            provider: 'google',
            options: {
                redirectTo: `${globalThis.location.origin}/auth/callback`,
            }
        });
    };

    return (
        <div className="min-h-screen flex flex-col items-center justify-center p-6 text-foreground">
            <AuraBackground />

            <main className="w-full max-w-lg">
                <header className="text-center mb-10 space-y-2">
                    <h2 className="text-3xl font-black tracking-tighter uppercase">Braand</h2>
                    <p className="text-foreground/40 font-light">
                        {isLogin ? "Welcome back to the premium workspace." : "Create your high-end professional identity."}
                    </p>
                </header>

                <GlassCard className="p-10" hover={false}>
                    <form onSubmit={handleSubmit} className="space-y-6">
                        <AnimatePresence mode="wait">
                            {!isLogin && (
                                <motion.div
                                    key="signup-fields"
                                    initial={{ opacity: 0, height: 0 }}
                                    animate={{ opacity: 1, height: "auto" }}
                                    exit={{ opacity: 0, height: 0 }}
                                    className="space-y-4 overflow-hidden"
                                >
                                    <div className="space-y-2">
                                        <label htmlFor="name-field" className="text-[10px] uppercase tracking-widest font-bold text-foreground/40">Full Name</label>
                                        <div className="relative">
                                            <User className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-foreground/20" />
                                            <input
                                                id="name-field"
                                                type="text"
                                                required={!isLogin}
                                                value={name}
                                                onChange={(e) => setName(e.target.value)}
                                                className="w-full pl-12 pr-4 py-4 rounded-2xl bg-white/5 border border-white/10 focus:border-aura-1 outline-none transition-all"
                                                placeholder="John Doe"
                                            />
                                        </div>
                                    </div>

                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="space-y-2">
                                            <label htmlFor="role-field" className="text-[10px] uppercase tracking-widest font-bold text-foreground/40">Role</label>
                                            <select
                                                id="role-field"
                                                value={role}
                                                onChange={(e) => setRole(e.target.value)}
                                                className="w-full px-4 py-4 rounded-2xl bg-white/5 border border-white/10 focus:border-aura-1 outline-none transition-all appearance-none"
                                            >
                                                <option value="Employee">Employee</option>
                                                <option value="Admin">Admin</option>
                                            </select>
                                        </div>
                                        <div className="space-y-2">
                                            <label htmlFor="dept-field" className="text-[10px] uppercase tracking-widest font-bold text-foreground/40">Department</label>
                                            <input
                                                id="dept-field"
                                                type="text"
                                                value={department}
                                                onChange={(e) => setDepartment(e.target.value)}
                                                className="w-full px-4 py-4 rounded-2xl bg-white/5 border border-white/10 focus:border-aura-1 outline-none transition-all"
                                                placeholder="General"
                                            />
                                        </div>
                                    </div>
                                </motion.div>
                            )}
                        </AnimatePresence>

                        <div className="space-y-2">
                            <label htmlFor="email-field" className="text-[10px] uppercase tracking-widest font-bold text-foreground/40">Email Address</label>
                            <div className="relative">
                                <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-foreground/20" />
                                <input
                                    id="email-field"
                                    type="email"
                                    required
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    className="w-full pl-12 pr-4 py-4 rounded-2xl bg-white/5 border border-white/10 focus:border-aura-1 outline-none transition-all"
                                    placeholder="name@company.com"
                                />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <label htmlFor="password-field" className="text-[10px] uppercase tracking-widest font-bold text-foreground/40">Password</label>
                            <div className="relative">
                                <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-foreground/20" />
                                <input
                                    id="password-field"
                                    type="password"
                                    required
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    className="w-full pl-12 pr-4 py-4 rounded-2xl bg-white/5 border border-white/10 focus:border-aura-1 outline-none transition-all"
                                    placeholder="••••••••"
                                />
                            </div>
                        </div>

                        {error && (
                            <p className="text-xs text-aura-2 font-medium bg-aura-2/10 p-4 rounded-xl">
                                {error}
                            </p>
                        )}

                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full py-5 bg-foreground text-background rounded-full font-bold transition-all hover:scale-[1.02] active:scale-[0.98] disabled:opacity-50"
                        >
                            {loading ? "Processing..." : (isLogin ? "Sign In" : "Create Account")}
                        </button>
                    </form>

                    <div className="relative my-8 text-center">
                        <div className="absolute inset-0 flex items-center">
                            <div className="w-full border-t border-white/10"></div>
                        </div>
                        <span className="relative px-4 bg-transparent text-[10px] uppercase tracking-widest text-foreground/20 bg-[#0a0a0a]">Or continue with</span>
                    </div>

                    <button
                        onClick={handleGoogleSignIn}
                        className="w-full py-4 border border-white/10 rounded-full flex items-center justify-center gap-3 hover:bg-white/5 transition-all text-sm font-medium"
                    >
                        <svg className="w-4 h-4" viewBox="0 0 24 24">
                            <path fill="currentColor" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                            <path fill="currentColor" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                            <path fill="currentColor" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" />
                            <path fill="currentColor" d="M12 5.38c1.62 0 3.06.56 4.21 1.66l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
                        </svg>
                        Google
                    </button>
                </GlassCard>

                <footer className="mt-8 text-center text-sm">
                    <button
                        onClick={() => setIsLogin(!isLogin)}
                        className="text-foreground/40 hover:text-foreground transition-colors"
                    >
                        {isLogin ? "Don't have an account? Sign up" : "Already have an account? Sign in"}
                    </button>
                </footer>
            </main>
        </div>
    );
}
