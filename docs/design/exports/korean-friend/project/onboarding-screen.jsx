// OnboardingScreen — bold direction: single vertical "story" with Alex
// on the left rail, its shape/emotion reflecting the step.
// Shown as a static frame at step 2/4 (goal picker) — the most info-rich.

function OnboardingDots({ step = 1, total = 4, dark }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
      {Array.from({ length: total }).map((_, i) => (
        <div key={i} style={{
          height: 4, borderRadius: 2,
          width: i === step ? 22 : 6,
          background: i <= step ? c.sage : c.hairline,
          transition: 'all .3s',
        }}/>
      ))}
    </div>
  );
}

function GoalCard({ title, hint, icon, selected, dark, accent }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '14px 14px',
      borderRadius: 18,
      background: selected ? c.sageWash : c.card,
      border: selected
        ? `1.5px solid ${c.sage}`
        : `1px solid ${c.hairline}`,
      boxShadow: selected ? '0 2px 10px oklch(0.62 0.08 155 / 0.08)' : 'none',
    }}>
      <div style={{
        width: 40, height: 40, borderRadius: 12,
        background: accent || c.beige,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        <Icon name={icon} size={20} color={selected ? c.sageDeep : c.ink} strokeWidth={2}/>
      </div>
      <div style={{ flex: 1 }}>
        <div style={{
          fontFamily: KF_TYPE.family, fontSize: 15, fontWeight: 700,
          color: c.ink, letterSpacing: -0.2,
        }}>{title}</div>
        <div style={{
          fontFamily: KF_TYPE.family, fontSize: 12, fontWeight: 500,
          color: c.ink3, marginTop: 2, letterSpacing: -0.1,
        }}>{hint}</div>
      </div>
      <div style={{
        width: 22, height: 22, borderRadius: 11,
        border: selected ? 'none' : `1.5px solid ${c.hairline}`,
        background: selected ? c.sage : 'transparent',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        {selected && <Icon name="check" size={13} color="#fff" strokeWidth={2.5}/>}
      </div>
    </div>
  );
}

function OnboardingScreen({ dark = false }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', height: '100%',
      background: c.canvas,
    }}>
      {/* Top: step progress + skip */}
      <div style={{
        padding: '16px 20px 10px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <OnboardingDots step={1} total={4} dark={dark}/>
        <div style={{
          fontFamily: KF_TYPE.family, fontSize: 13, fontWeight: 500,
          color: c.ink3,
        }}>Skip</div>
      </div>

      {/* Alex + intro */}
      <div style={{ padding: '24px 22px 4px' }}>
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 14 }}>
          <Alex size={72} emotion="thinking" dark={dark}/>
          <div style={{
            flex: 1,
            background: c.card,
            border: `1px solid ${c.hairline}`,
            borderRadius: '18px 18px 18px 6px',
            padding: '12px 14px',
            fontFamily: KF_TYPE.family, fontSize: 14, fontWeight: 500,
            color: c.ink, lineHeight: 1.45, letterSpacing: -0.2,
          }}>
            Nice. So what brings you here, really?
          </div>
        </div>
      </div>

      {/* Headline */}
      <div style={{ padding: '20px 22px 14px' }}>
        <div style={{
          fontFamily: KF_TYPE.family,
          fontSize: 28, fontWeight: 700, lineHeight: 1.15,
          color: c.ink, letterSpacing: -0.6,
        }}>
          Pick what&nbsp;matters<br/>
          <span style={{ color: c.sageDeep }}>most to you</span>
        </div>
        <div style={{
          marginTop: 8,
          fontFamily: KF_TYPE.family, fontSize: 13, fontWeight: 500,
          color: c.ink2, lineHeight: 1.45,
        }}>
          I&rsquo;ll shape our chats around this. You can change it anytime.
        </div>
      </div>

      {/* Cards */}
      <div style={{
        flex: 1, overflowY: 'auto',
        padding: '4px 16px 16px',
        display: 'flex', flexDirection: 'column', gap: 10,
      }}>
        <GoalCard dark={dark}
          icon="chat" title="Daily speaking practice"
          hint="Short, natural chats — 5 min a day"
          selected={true} accent={c.sageWash}/>
        <GoalCard dark={dark}
          icon="globe" title="Travel & small talk"
          hint="Order coffee, ask directions, get by"
          accent={c.mustardSoft}/>
        <GoalCard dark={dark}
          icon="bolt" title="Work & meetings"
          hint="Emails, standups, presenting ideas"/>
        <GoalCard dark={dark}
          icon="heart" title="Just for fun"
          hint="Movies, hobbies, making friends"/>
      </div>

      {/* CTA */}
      <div style={{
        padding: '10px 18px 18px',
        background: c.canvas,
        borderTop: `0.5px solid ${c.hairline}`,
      }}>
        <div style={{
          height: 52, borderRadius: 16,
          background: c.sage, color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: KF_TYPE.family, fontSize: 16, fontWeight: 700,
          letterSpacing: -0.2, gap: 6,
          boxShadow: '0 4px 14px oklch(0.62 0.08 155 / 0.3)',
        }}>
          Continue
          <Icon name="chevr" size={18} color="#fff" strokeWidth={2.4}/>
        </div>
        <div style={{
          marginTop: 10, textAlign: 'center',
          fontFamily: KF_TYPE.family, fontSize: 11, fontWeight: 500,
          color: c.ink3,
        }}>Step 2 of 4 · About 30 seconds</div>
      </div>
    </div>
  );
}

Object.assign(window, { OnboardingScreen });
