import { AuraBackground } from "@/components/ui/AuraBackground";
import { ArrowRight, Sparkles } from "lucide-react";
import Link from "next/link";

export default function Home() {
  return (
    <div className="relative min-h-screen flex flex-col items-center justify-center p-6 text-foreground">
      <AuraBackground />

      <main className="max-w-4xl w-full flex flex-col items-center text-center space-y-12">
        {/* Badge */}
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full glass text-xs font-medium tracking-wider uppercase opacity-0 transition-all duration-1000 animate-in fade-in slide-in-from-bottom-4">
          <Sparkles className="w-3 h-3 text-aura-1" />
          <span>Elevated Experience</span>
        </div>

        {/* Hero Text */}
        <div className="space-y-6">
          <h1 className="text-6xl md:text-8xl font-bold tracking-tighter text-balance">
            Editorial <span className="text-transparent bg-clip-text bg-gradient-to-r from-aura-1 to-aura-2">Minimalism</span>
          </h1>
          <p className="max-w-2xl mx-auto text-lg md:text-xl text-foreground/60 leading-relaxed font-light">
            Your Flutter app, reimagined for the web. High performance meets premium aesthetics with Gradient Aura UI.
          </p>
        </div>

        {/* Actions */}
        <div className="flex flex-col sm:flex-row gap-4">
          <Link
            href="/dashboard"
            className="group relative inline-flex items-center gap-2 px-8 py-4 bg-foreground text-background rounded-full font-semibold overflow-hidden transition-all hover:pr-10"
          >
            <span>Explore Dashboard</span>
            <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
          </Link>

          <button className="px-8 py-4 rounded-full border border-foreground/10 hover:bg-foreground/5 transition-all font-medium">
            View Analytics
          </button>
        </div>

        {/* Preview Grid Placeholder */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 w-full pt-12">
          {[1, 2, 3].map((i) => (
            <div key={i} className="glass aspect-square rounded-3xl p-8 flex flex-col justify-end text-left space-y-2 group transition-all hover:scale-[1.02]">
              <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-aura-1 to-aura-3 opacity-20" />
              <h3 className="text-xl font-bold">Feature {i}</h3>
              <p className="text-sm text-foreground/40 leading-snug">
                Premium micro-interactions and smooth transitions.
              </p>
            </div>
          ))}
        </div>
      </main>

      {/* Footer Branding */}
      <footer className="absolute bottom-8 text-[10px] tracking-widest uppercase opacity-20">
        Braand / Web Native v2.0
      </footer>
    </div>
  );
}
