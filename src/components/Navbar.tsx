'use client';

import { useEffect, useState } from 'react';
import { motion, useScroll, useTransform } from 'framer-motion';

const links = ['About', 'Experience', 'Projects', 'Contact'];

export default function Navbar() {
  const { scrollY } = useScroll();
  const [activeSection, setActiveSection] = useState('');

  const bg = useTransform(
    scrollY,
    [0, 150],
    ['rgba(18, 18, 18, 0)', 'rgba(18, 18, 18, 0.85)']
  );
  
  const border = useTransform(
    scrollY,
    [0, 150],
    ['rgba(255, 255, 255, 0)', 'rgba(255, 255, 255, 0.05)']
  );

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setActiveSection(entry.target.id);
          }
        });
      },
      { threshold: 0.25, rootMargin: '-20% 0px -50% 0px' }
    );

    const sections = ['about', 'experience', 'projects', 'contact'];
    sections.forEach((id) => {
      const el = document.getElementById(id);
      if (el) observer.observe(el);
    });

    return () => observer.disconnect();
  }, []);

  return (
    <motion.header
      style={{ background: bg, borderColor: border }}
      className="fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-6 py-4 sm:px-12 border-b backdrop-blur-md transition-all duration-300"
    >
      <div className="flex items-center gap-1.5 select-none">
        <span className="text-sm font-black tracking-[0.2em] text-white">AHSAN</span>
        <span className="h-1.5 w-1.5 rounded-full bg-[#ef4444] animate-pulse" />
      </div>

      <nav className="hidden sm:flex items-center gap-8">
        {links.map((l) => {
          const id = l.toLowerCase();
          const isActive = activeSection === id;
          return (
            <a
              key={l}
              href={`#${id}`}
              className={`relative text-[10px] font-bold tracking-[0.2em] uppercase transition-colors duration-300 ${
                isActive ? 'text-[#ef4444]' : 'text-white/40 hover:text-white/80'
              }`}
            >
              {l}
              {isActive && (
                <motion.span
                  layoutId="activeIndicator"
                  className="absolute -bottom-1 left-0 right-0 h-[1.5px] bg-[#ef4444]"
                  transition={{ type: 'spring', stiffness: 380, damping: 30 }}
                />
              )}
            </a>
          );
        })}
      </nav>

      <motion.a
        whileHover={{ scale: 1.03 }}
        whileTap={{ scale: 0.98 }}
        href="mailto:ahsan123shahid@gmail.com"
        className="rounded-full border border-white/[0.12] bg-white/[0.01] px-5 py-2 text-[10px] font-bold tracking-[0.15em] uppercase text-white/80 transition-colors duration-300 hover:border-[#ef4444]/30 hover:bg-[#ef4444]/5 hover:text-white cursor-pointer"
      >
        Contact
      </motion.a>
    </motion.header>
  );
}
