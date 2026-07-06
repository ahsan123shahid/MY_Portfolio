'use client';

import { useRef } from 'react';
import ScrollyCanvas from './ScrollyCanvas';
import Overlay from './Overlay';

export default function ScrollySection() {
  const sectionRef = useRef<HTMLDivElement>(null);

  return (
    <section ref={sectionRef} className="relative h-[500vh]">
      <div className="sticky top-0 h-screen w-full overflow-hidden bg-[#121212]">
        <ScrollyCanvas containerRef={sectionRef} />
        <Overlay containerRef={sectionRef} />
      </div>
    </section>
  );
}
