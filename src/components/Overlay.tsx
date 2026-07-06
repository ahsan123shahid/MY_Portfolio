'use client';

import { useScroll, useTransform, motion, type MotionValue } from 'framer-motion';

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
    at: 0.38,
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
    at: 0.72,
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
  scrollYProgress,
}: {
  section: (typeof sections)[0];
  scrollYProgress: MotionValue<number>;
}) {
  const range = 0.16;
  const start = Math.max(section.at - range, 0);
  const end = Math.min(section.at + range, 1);

  // Smooth fade-in/out
  const opacity = useTransform(
    scrollYProgress,
    [start, section.at, end],
    [0, 1, 0]
  );

  // Parallax Y offset
  const y = useTransform(
    scrollYProgress,
    [start, end],
    [60, -60]
  );

  // Soft scale zoom
  const scale = useTransform(
    scrollYProgress,
    [start, section.at, end],
    [0.96, 1, 1.04]
  );

  return (
    <motion.div
      className={`absolute inset-0 flex ${section.align} pointer-events-none z-10`}
      style={{ opacity, y, scale }}
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
    </motion.div>
  );
}

export default function Overlay({ containerRef }: { containerRef?: React.RefObject<HTMLDivElement> }) {
  const { scrollYProgress } = useScroll(
    containerRef
      ? { target: containerRef as any, offset: ['start start', 'end end'] }
      : undefined
  );

  const scrollIndicatorOpacity = useTransform(scrollYProgress, [0, 0.08], [1, 0]);

  return (
    <div className="absolute inset-0 z-10">
      {sections.map((s, i) => (
        <Section key={i} section={s} scrollYProgress={scrollYProgress} />
      ))}

      {/* Floating Scroll Indicator */}
      <motion.div 
        style={{ opacity: scrollIndicatorOpacity }}
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
      </motion.div>
    </div>
  );
}
