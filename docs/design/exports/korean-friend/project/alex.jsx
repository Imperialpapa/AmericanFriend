// Alex — abstract pebble mascot.
// Body = organic rounded blob (border-radius trick), two eye dots, optional mustard cheek blush.
// No mouth, no gender cues. Emotion = variations in body shape + eye shape.

function Alex({ size = 64, emotion = 'calm', dark = false, style = {} }) {
  const c = dark ? KF.dark : KF.light;
  // emotion → { bodyRadius, eyeH, eyeGap, blushOp, tilt, yOffset }
  const moods = {
    calm:      { br: '58% 42% 55% 45% / 50% 55% 45% 50%', eyeH: 6, eyeGap: 0.42, blush: 0.9, tilt: 0 },
    thinking:  { br: '55% 45% 60% 40% / 45% 60% 40% 55%', eyeH: 3, eyeGap: 0.36, blush: 0.4, tilt: -6 },
    celebrate: { br: '60% 40% 50% 50% / 60% 40% 60% 40%', eyeH: 8, eyeGap: 0.44, blush: 1.0, tilt: 4 },
    listening: { br: '55% 45% 50% 50% / 55% 45% 50% 50%', eyeH: 7, eyeGap: 0.42, blush: 0.7, tilt: 0 },
  };
  const m = moods[emotion] || moods.calm;
  const eyeSize = Math.max(3, size * 0.09);
  const blushSize = size * 0.12;

  return (
    <div style={{
      width: size, height: size, position: 'relative',
      transform: `rotate(${m.tilt}deg)`,
      ...style,
    }}>
      {/* shadow */}
      <div style={{
        position: 'absolute', left: '12%', right: '12%', bottom: '-4%',
        height: size * 0.08, borderRadius: '50%',
        background: c.sageDeep, opacity: 0.15, filter: 'blur(6px)',
      }} />
      {/* body */}
      <div style={{
        position: 'absolute', inset: 0,
        background: `linear-gradient(155deg, ${c.sage} 0%, ${c.sageDeep} 100%)`,
        borderRadius: m.br,
        boxShadow: `inset ${size * 0.05}px ${size * 0.05}px ${size * 0.1}px rgba(255,255,255,0.18),
                    inset -${size * 0.04}px -${size * 0.04}px ${size * 0.08}px rgba(0,0,0,0.12)`,
      }} />
      {/* highlight */}
      <div style={{
        position: 'absolute', top: '14%', left: '18%',
        width: size * 0.28, height: size * 0.22,
        borderRadius: '50%',
        background: 'rgba(255,255,255,0.35)', filter: 'blur(3px)',
      }} />
      {/* eyes */}
      <div style={{
        position: 'absolute', top: '46%', left: 0, right: 0,
        display: 'flex', justifyContent: 'center', gap: size * m.eyeGap,
        transform: `translateY(-${eyeSize / 2}px)`,
      }}>
        <div style={{
          width: eyeSize, height: m.eyeH,
          borderRadius: emotion === 'thinking' ? 2 : 999,
          background: '#1a2420',
        }} />
        <div style={{
          width: eyeSize, height: m.eyeH,
          borderRadius: emotion === 'thinking' ? 2 : 999,
          background: '#1a2420',
        }} />
      </div>
      {/* mustard cheek blush */}
      {m.blush > 0 && (
        <>
          <div style={{
            position: 'absolute', top: '58%', left: '14%',
            width: blushSize, height: blushSize * 0.7, borderRadius: '50%',
            background: c.mustard, opacity: m.blush * 0.55, filter: 'blur(2px)',
          }} />
          <div style={{
            position: 'absolute', top: '58%', right: '14%',
            width: blushSize, height: blushSize * 0.7, borderRadius: '50%',
            background: c.mustard, opacity: m.blush * 0.55, filter: 'blur(2px)',
          }} />
        </>
      )}
      {/* antenna / sparkle for celebrate */}
      {emotion === 'celebrate' && (
        <div style={{
          position: 'absolute', top: -size * 0.12, right: -size * 0.08,
          width: size * 0.22, height: size * 0.22,
          background: c.mustard,
          clipPath: 'polygon(50% 0, 60% 40%, 100% 50%, 60% 60%, 50% 100%, 40% 60%, 0 50%, 40% 40%)',
        }} />
      )}
      {/* thinking dots */}
      {emotion === 'thinking' && (
        <div style={{
          position: 'absolute', top: -size * 0.14, right: -size * 0.18,
          display: 'flex', gap: 3, alignItems: 'center',
        }}>
          {[0.5, 0.7, 1].map((o, i) => (
            <div key={i} style={{
              width: size * 0.06, height: size * 0.06, borderRadius: '50%',
              background: c.sage, opacity: o,
            }} />
          ))}
        </div>
      )}
    </div>
  );
}

Object.assign(window, { Alex });
