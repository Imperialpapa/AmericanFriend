// ChatScreen — main dialogue with Alex.
// Bold move: "learning layer" drawer under Alex messages (expanded by default on one msg),
// showing translation + correction hints in a single continuous surface.

function ChatHeader({ dark }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '10px 14px 12px',
      borderBottom: `0.5px solid ${c.hairline}`,
      background: c.paper,
    }}>
      <div style={{ width: 36, display: 'flex', alignItems: 'center' }}>
        <Icon name="chevr" size={22} color={c.ink2} strokeWidth={2}
          style={{ transform: 'scaleX(-1)' }}/>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1 }}>
        <div style={{ position: 'relative' }}>
          <Alex size={34} emotion="listening" dark={dark}/>
          <div style={{
            position: 'absolute', right: -1, bottom: -1,
            width: 9, height: 9, borderRadius: '50%',
            background: c.sage,
            border: `1.5px solid ${c.paper}`,
          }}/>
        </div>
        <div>
          <div style={{
            fontFamily: KF_TYPE.family, fontSize: 15, fontWeight: 700,
            color: c.ink, letterSpacing: -0.2,
          }}>Alex</div>
          <div style={{
            fontFamily: KF_TYPE.family, fontSize: 11, fontWeight: 500,
            color: c.ink3, marginTop: 1,
          }}>Day 14 · Cafe chat</div>
        </div>
      </div>
      <StreakChip days={14} dark={dark} />
      <Icon name="stats" size={20} color={c.ink2}/>
    </div>
  );
}

function MissionStrip({ dark }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{
      margin: '10px 14px 0', padding: '10px 12px',
      background: c.sageWash, borderRadius: 14,
      display: 'flex', alignItems: 'center', gap: 10,
    }}>
      <div style={{
        width: 28, height: 28, borderRadius: 8,
        background: c.sage, color: c.paper,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <Icon name="target" size={15} color={c.paper} strokeWidth={2.2}/>
      </div>
      <div style={{ flex: 1 }}>
        <div style={{
          fontFamily: KF_TYPE.family, fontSize: 12, fontWeight: 600,
          color: c.ink, letterSpacing: -0.1,
        }}>Today&rsquo;s mission · 2 of 3</div>
        <div style={{ marginTop: 4 }}>
          <XPBar value={0.66} dark={dark}/>
        </div>
      </div>
      <div style={{
        fontFamily: KF_TYPE.family, fontSize: 11, fontWeight: 700,
        color: c.sageDeep, letterSpacing: 0.2,
      }}>+40 XP</div>
    </div>
  );
}

// Bubble for Alex (left) — gets optional learning drawer
function AlexMsg({ text, translation, correction, pronunciation, open, dark, showAvatar = true }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end', padding: '0 14px' }}>
      <div style={{ width: 28, flexShrink: 0 }}>
        {showAvatar && <Alex size={28} emotion="calm" dark={dark}/>}
      </div>
      <div style={{ maxWidth: '78%' }}>
        <div style={{
          background: c.card, color: c.ink,
          padding: '11px 14px',
          borderRadius: '18px 18px 18px 6px',
          fontFamily: KF_TYPE.family, fontSize: 15, fontWeight: 500,
          lineHeight: 1.45, letterSpacing: -0.2,
          boxShadow: dark ? 'none' : '0 1px 2px rgba(30,50,40,0.04)',
          border: dark ? `0.5px solid ${c.hairline}` : 'none',
        }}>
          {text}
        </div>
        {open && (
          <div style={{
            marginTop: 4, marginLeft: 0,
            background: c.beige, borderRadius: 14,
            padding: '10px 12px',
            display: 'flex', flexDirection: 'column', gap: 8,
            border: `0.5px solid ${c.hairline}`,
          }}>
            {translation && (
              <div style={{ display: 'flex', gap: 8, alignItems: 'flex-start' }}>
                <div style={{
                  width: 20, flexShrink: 0, paddingTop: 1,
                  color: c.ink3,
                }}>
                  <Icon name="translate" size={14} color={c.ink3}/>
                </div>
                <div style={{
                  flex: 1, fontFamily: KF_TYPE.family, fontSize: 13,
                  fontWeight: 500, color: c.ink2, lineHeight: 1.45,
                }}>{translation}</div>
              </div>
            )}
            {pronunciation && (
              <div style={{ display: 'flex', gap: 8, alignItems: 'flex-start' }}>
                <div style={{ width: 20, flexShrink: 0, paddingTop: 1, color: c.ink3 }}>
                  <Icon name="wave" size={14} color={c.ink3}/>
                </div>
                <div style={{
                  flex: 1, fontFamily: KF_TYPE.family, fontSize: 12,
                  fontWeight: 500, color: c.ink3, fontStyle: 'italic',
                  letterSpacing: 0.2,
                }}>{pronunciation}</div>
              </div>
            )}
            {correction && (
              <div style={{
                marginTop: 2, paddingTop: 8,
                borderTop: `0.5px dashed ${c.hairline}`,
                display: 'flex', gap: 8, alignItems: 'flex-start',
              }}>
                <div style={{ width: 20, flexShrink: 0, paddingTop: 1 }}>
                  <Icon name="sparkle" size={14} color={c.mustard} strokeWidth={2}/>
                </div>
                <div style={{
                  flex: 1, fontFamily: KF_TYPE.family, fontSize: 12,
                  fontWeight: 500, color: c.ink2, lineHeight: 1.4,
                }}>
                  <span style={{ color: c.ink3 }}>You said </span>
                  <span style={{
                    textDecoration: 'line-through',
                    textDecorationColor: c.coral,
                    color: c.ink2,
                  }}>{correction.from}</span>
                  <span style={{ color: c.ink3 }}> → try </span>
                  <span style={{ color: c.sageDeep, fontWeight: 700 }}>{correction.to}</span>
                </div>
              </div>
            )}
            <div style={{
              display: 'flex', gap: 6, marginTop: 2,
            }}>
              <button style={{
                flex: 1, height: 32, borderRadius: 10,
                border: `1px solid ${c.hairline}`, background: c.paper,
                fontFamily: KF_TYPE.family, fontSize: 12, fontWeight: 600,
                color: c.ink, display: 'flex', alignItems: 'center', justifyContent: 'center',
                gap: 5,
              }}>
                <Icon name="play" size={11} color={c.sage}/>
                Hear it
              </button>
              <button style={{
                flex: 1, height: 32, borderRadius: 10,
                border: `1px solid ${c.hairline}`, background: c.paper,
                fontFamily: KF_TYPE.family, fontSize: 12, fontWeight: 600,
                color: c.ink, display: 'flex', alignItems: 'center', justifyContent: 'center',
                gap: 5,
              }}>
                <Icon name="cards" size={12} color={c.sage}/>
                Save word
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function UserMsg({ text, dark }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{ display: 'flex', justifyContent: 'flex-end', padding: '0 14px' }}>
      <div style={{
        maxWidth: '76%',
        background: c.sage, color: '#fff',
        padding: '11px 14px',
        borderRadius: '18px 18px 6px 18px',
        fontFamily: KF_TYPE.family, fontSize: 15, fontWeight: 500,
        lineHeight: 1.45, letterSpacing: -0.2,
        boxShadow: '0 1px 2px rgba(30,60,50,0.12)',
      }}>{text}</div>
    </div>
  );
}

function SuggestionRow({ dark }) {
  const c = dark ? KF.dark : KF.light;
  const opts = ['Yes, it was delicious', 'Not really, too bitter', 'What did you have?'];
  return (
    <div style={{
      display: 'flex', gap: 6, overflowX: 'auto',
      padding: '4px 14px 0', scrollbarWidth: 'none',
    }}>
      {opts.map((o, i) => (
        <div key={i} style={{
          flexShrink: 0, padding: '7px 11px',
          background: c.paper,
          border: `1px solid ${c.hairline}`,
          borderRadius: 999,
          fontFamily: KF_TYPE.family, fontSize: 12, fontWeight: 500,
          color: c.ink2, letterSpacing: -0.1,
          display: 'flex', alignItems: 'center', gap: 5,
        }}>
          {i === 0 && <Icon name="sparkle" size={11} color={c.mustard}/>}
          {o}
        </div>
      ))}
    </div>
  );
}

function Composer({ dark, platform }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{
      padding: '10px 12px 12px',
      display: 'flex', gap: 8, alignItems: 'center',
      borderTop: `0.5px solid ${c.hairline}`,
      background: c.paper,
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: 18,
        background: c.beige,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <Icon name="plus" size={18} color={c.ink2}/>
      </div>
      <div style={{
        flex: 1, height: 40, borderRadius: 20,
        background: c.beige,
        padding: '0 14px',
        display: 'flex', alignItems: 'center',
        fontFamily: KF_TYPE.family, fontSize: 14, fontWeight: 500,
        color: c.ink3,
      }}>
        Type or tap mic…
      </div>
      <div style={{
        width: 40, height: 40, borderRadius: 20,
        background: c.sage,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 2px 6px oklch(0.62 0.08 155 / 0.3)',
      }}>
        <Icon name="mic" size={18} color="#fff" strokeWidth={2}/>
      </div>
    </div>
  );
}

function ChatScreen({ dark = false, platform = 'ios' }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', height: '100%',
      background: c.canvas,
    }}>
      <ChatHeader dark={dark}/>
      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 8, paddingTop: 0 }}>
        <MissionStrip dark={dark}/>
        <div style={{
          textAlign: 'center', padding: '18px 0 14px',
          fontFamily: KF_TYPE.family, fontSize: 11, fontWeight: 600,
          color: c.ink3, letterSpacing: 0.4, textTransform: 'uppercase',
        }}>Today · 8:14 AM</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <AlexMsg dark={dark}
            text="Morning! Did you have coffee yet, or are you running late again?"
            translation="좋은 아침! 커피 벌써 마셨어, 아니면 또 늦잠 잤어?"
            pronunciation="/ˈmɔːr.nɪŋ/ · light on the 'r'"
            open={true}/>
          <UserMsg dark={dark} text="I had one but it was too bitter today"/>
          <AlexMsg dark={dark}
            text="Oof, bitter coffee is the worst. Was it from a new place?"
            correction={{ from: 'I had one but it was too bitter', to: 'I had one, but it was too bitter today' }}
            open={false}
            showAvatar={true}/>
        </div>
        <SuggestionRow dark={dark}/>
      </div>
      <AdBand dark={dark}/>
      <Composer dark={dark} platform={platform}/>
    </div>
  );
}

Object.assign(window, { ChatScreen });
