'use client';

import { useRef } from 'react';
import ScrollyCanvas from './ScrollyCanvas';
import Overlay from './Overlay';

export default function ScrollySection() {
  const sectionRef = useRef<HTMLDivElement>(null);

  return (
    <section ref={sectionRef} className="relative w-full" style={{ height: '400vh', minHeight: '2400px' }}>
      <div className="sticky top-0 w-full overflow-hidden bg-[#121212]" style={{ height: '100vh', minHeight: '500px' }}>
        <ScrollyCanvas containerRef={sectionRef} />
        <Overlay containerRef={sectionRef} />
      </div>
    </section>
  );
}
