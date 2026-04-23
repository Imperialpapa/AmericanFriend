// Modern Sage palette + type tokens for Korean Friend redesign.
// Commit: sage primary, warm beige surface, mustard accent, forest ink.
// All colors in oklch; accents share chroma/lightness band, only hue varies.

const KF = {
  light: {
    // surfaces
    paper:    'oklch(0.985 0.004 95)',   // near-white with warm undertone
    canvas:   'oklch(0.965 0.008 90)',   // page bg
    card:     '#ffffff',
    beige:    'oklch(0.945 0.022 85)',   // secondary surface
    beigeIn:  'oklch(0.915 0.028 85)',   // deeper beige
    // ink
    ink:      'oklch(0.24 0.02 155)',    // forest ink (primary text)
    ink2:     'oklch(0.45 0.02 155)',
    ink3:     'oklch(0.62 0.015 150)',
    hairline: 'oklch(0.90 0.012 130)',
    // brand
    sage:     'oklch(0.62 0.08 155)',
    sageDeep: 'oklch(0.46 0.08 155)',
    sageSoft: 'oklch(0.88 0.05 150)',
    sageWash: 'oklch(0.955 0.025 150)',
    // accents (matched L/C, hue only)
    mustard:  'oklch(0.78 0.14 85)',
    mustardSoft: 'oklch(0.92 0.07 90)',
    coral:    'oklch(0.78 0.14 35)',   // used sparingly for streak flame
    indigo:   'oklch(0.55 0.12 265)',  // info / link
  },
  dark: {
    paper:    'oklch(0.18 0.012 155)',
    canvas:   'oklch(0.14 0.01 155)',
    card:     'oklch(0.22 0.015 155)',
    beige:    'oklch(0.26 0.02 90)',
    beigeIn:  'oklch(0.30 0.025 90)',
    ink:      'oklch(0.96 0.01 95)',
    ink2:     'oklch(0.75 0.015 130)',
    ink3:     'oklch(0.58 0.015 130)',
    hairline: 'oklch(0.30 0.012 150)',
    sage:     'oklch(0.72 0.10 155)',
    sageDeep: 'oklch(0.58 0.09 155)',
    sageSoft: 'oklch(0.38 0.05 150)',
    sageWash: 'oklch(0.25 0.03 150)',
    mustard:  'oklch(0.82 0.14 85)',
    mustardSoft: 'oklch(0.35 0.06 85)',
    coral:    'oklch(0.80 0.14 35)',
    indigo:   'oklch(0.72 0.11 265)',
  },
};

const KF_TYPE = {
  family: "'Pretendard Variable', 'Pretendard', -apple-system, system-ui, sans-serif",
  display: { size: 34, weight: 700, lh: 1.15, track: -0.02 },
  h1:      { size: 28, weight: 700, lh: 1.2,  track: -0.02 },
  h2:      { size: 20, weight: 600, lh: 1.25, track: -0.015 },
  body:    { size: 16, weight: 500, lh: 1.45, track: -0.01 },
  bodyR:   { size: 16, weight: 400, lh: 1.5,  track: -0.005 },
  meta:    { size: 13, weight: 500, lh: 1.35, track:  0 },
  tiny:    { size: 11, weight: 600, lh: 1.2,  track:  0.02 },
};

// tiny ad band — honest placeholder
function AdBand({ dark = false }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{
      height: 50,
      background: `repeating-linear-gradient(135deg, ${c.beige} 0 8px, ${c.beigeIn} 8px 16px)`,
      borderTop: `0.5px solid ${c.hairline}`,
      borderBottom: `0.5px solid ${c.hairline}`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      position: 'relative',
    }}>
      <div style={{
        position: 'absolute', left: 10, top: 6,
        fontFamily: KF_TYPE.family,
        fontSize: 9, fontWeight: 700, letterSpacing: 0.8,
        color: c.ink3, textTransform: 'uppercase',
        background: c.paper, padding: '2px 6px', borderRadius: 3,
      }}>AD</div>
      <div style={{
        fontFamily: KF_TYPE.family, fontSize: 12, color: c.ink3, fontWeight: 500,
      }}>320 × 50  ·  banner placeholder</div>
    </div>
  );
}

Object.assign(window, { KF, KF_TYPE, AdBand });
