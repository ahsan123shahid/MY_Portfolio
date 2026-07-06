'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';

const sections = [
  {
    at: 0.05,
    subtitle: 'M. AHSAN SHAHID',
    titleNode: (
      <>
        AI SYSTEMS <br />
        THAT <span className="text-[#ef4444]">SCALE.</span>
      </>
    ),
    description: 'I design and build intelligent digital experiences that are bold, strategic, and production-grade.',
    align: 'justify-center items-center text-center' as const,
    descAlign: 'mx-auto',
    showCta: true,
  },
  {
    at: 0.35,
    subtitle: '01 / PHILOSOPHY',
    titleNode: (
      <>
        BUILDING <br />
        <span className="text-[#ef4444]">REAL AI.</span>
      </>
    ),
    description: 'Designing custom RAG pipelines, fine-tuned embeddings, and high-throughput vector search architectures—not just calling standard API wrappers.',
    align: 'justify-start items-center text-left px-6 sm:px-16 md:px-24' as const,
    descAlign: 'mr-auto',
    showCta: false,
  },
  {
    at: 0.65,
    subtitle: '02 / ENGINEERING',
    titleNode: (
      <>
        BRIDGING <br />
        TWO <span className="text-[#ef4444]">WORLDS.</span>
      </>
    ),
    description: 'Fusing the intelligence of advanced machine learning models with production-grade full-stack backend and frontend engineering.',
    align: 'justify-end items-center text-right px-6 sm:px-16 md:px-24' as const,
    descAlign: 'ml-auto',
    showCta: false,
  },
];

function Section({
  section,
  progress,
}: {
  section: (typeof sections)[0];
  progress: number;
}) {
  const range = 0.16;
  const start = Math.max(section.at - range, 0);
  const end = Math.min(section.at + range, 1);

  // Math-based linear interpolation for CSS values
  let opacity = 0;
  let y = 30;
  let scale = 0.96;

  if (progress >= start && progress <= end) {
    // Opacity fade-in / fade-out
    if (progress < section.at) {
      const denom = section.at - start;
      opacity = denom > 0 ? (progress - start) / denom : 1;
    } else {
      const denom = end - section.at;
      opacity = denom > 0 ? 1 - (progress - section.at) / denom : 0;
    }

    // Parallax Y offset (30 to -30)
    const ratio = (progress - start) / (end - start);
    y = 30 - ratio * 60;

    // Scale zoom (0.96 to 1.04)
    scale = 0.96 + ratio * 0.08;
  } else if (progress > end) {
    opacity = 0;
    y = -30;
    scale = 1.04;
  }

  return (
    <div
      className={`absolute inset-0 flex ${section.align} pointer-events-none z-10`}
      style={{
        opacity,
        transform: `translateY(${y}px) scale(${scale})`,
        willChange: 'transform, opacity',
        transition: 'opacity 0.15s ease-out, transform 0.15s ease-out',
      }}
    >
      <div className="max-w-5xl px-6 select-none pointer-events-auto">
        {section.subtitle && (
          <span className="inline-block mb-3 text-xs sm:text-sm font-semibold tracking-[0.25em] uppercase text-[#ef4444]">
            {section.subtitle}
          </span>
        )}
        <h1 className="text-5xl sm:text-7xl md:text-8xl lg:text-9xl font-black leading-[0.9] tracking-tighter uppercase text-white mb-6 select-none">
          {section.titleNode}
        </h1>
        {section.description && (
          <p className={`max-w-md sm:max-w-lg text-sm sm:text-base leading-relaxed text-white/50 mb-8 ${section.descAlign}`}>
            {section.description}
          </p>
        )}
        {section.showCta && (
          <button
            onClick={() => {
              const el = document.getElementById('projects');
              if (el) el.scrollIntoView({ behavior: 'smooth' });
            }}
            className="group pointer-events-auto inline-flex items-center gap-3 rounded-lg border border-white/20 bg-transparent px-6 py-3.5 text-xs font-bold uppercase tracking-[0.20em] text-white transition-all duration-300 hover:border-[#ef4444] hover:bg-[#ef4444]/10 cursor-pointer"
          >
            <span>View My Work</span>
            <span className="text-xs transition-transform duration-300 group-hover:translate-x-0.5 group-hover:-translate-y-0.5">
              ↗
            </span>
          </button>
        )}
      </div>
    </div>
  );
}

export default function Overlay({ containerRef }: { containerRef?: React.RefObject<HTMLDivElement> }) {
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const handleScroll = () => {
      const section = containerRef?.current;
      if (!section) return;
      const rect = section.getBoundingClientRect();
      const scrollableHeight = rect.height - window.innerHeight;
      if (scrollableHeight <= 0) return;
      
      const scrolled = -rect.top;
      const p = Math.min(Math.max(scrolled / scrollableHeight, 0), 1);
      setProgress(p);
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    handleScroll(); // Initial check
    
    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, [containerRef]);

  const scrollIndicatorOpacity = progress < 0.08 ? 1 - progress / 0.08 : 0;

  return (
    <div className="absolute inset-0 z-10 pointer-events-none">
      {sections.map((s, i) => (
        <Section key={i} section={s} progress={progress} />
      ))}

      {/* Floating Scroll Indicator */}
      <div 
        style={{ 
          opacity: scrollIndicatorOpacity,
          transition: 'opacity 0.2s ease-out'
        }}
        className="absolute bottom-16 left-1/2 -translate-x-1/2 flex flex-col items-center gap-4 pointer-events-none z-20"
      >
        <span className="text-[10px] font-black tracking-[0.4em] uppercase text-white/70 select-none">
          Scroll to explore
        </span>
        <div className="relative h-20 w-[2px] bg-white/20 overflow-hidden rounded-full">
          {/* Glowing laser bead flowing down the track */}
          <motion.div 
            animate={{ 
              y: [-20, 80],
              opacity: [0, 1, 1, 0]
            }}
            transition={{
              duration: 2.0,
              repeat: Infinity,
              ease: "easeInOut"
            }}
            className="absolute left-0 right-0 h-5 bg-[#ef4444] shadow-[0_0_12px_#ef4444]"
          />
        </div>
      </div>
    </div>
  );
}
