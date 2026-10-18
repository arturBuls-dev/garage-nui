import { useCallback, useEffect, useMemo, useState, type CSSProperties, type MouseEvent } from 'react';
import { fetchNui, isInGame, useNuiEvent } from './nui';

type OpenMessage = { action: 'open'; cars: string[]; favorites?: string[] };

const label = (model: string) => model.charAt(0).toUpperCase() + model.slice(1);

// Images live in web/public/cars/<model>.webp
const imageUrl = (model: string) => `${import.meta.env.BASE_URL}cars/${model}.webp`;

const DEV_CARS = ['adder', 'sultan', 'kuruma', 'comet2', 'buffalo', 'dominator'];

export default function App() {
  // In a browser (development mode) show the window right away with sample data
  const [visible, setVisible] = useState(!isInGame());
  const [cars, setCars] = useState<string[]>(isInGame() ? [] : DEV_CARS);
  const [favorites, setFavorites] = useState<string[]>([]);
  const [missing, setMissing] = useState<Record<string, boolean>>({});

  useNuiEvent<OpenMessage>('open', useCallback((data) => {
    setCars(data.cars);
    setFavorites(data.favorites ?? []);
    setVisible(true);
  }, []));
  useNuiEvent('close', useCallback(() => setVisible(false), []));

  const close = useCallback(() => {
    setVisible(false);
    fetchNui('close');
  }, []);

  // Escape closes the window
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && visible) close();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [visible, close]);

  const pick = (model: string) => {
    setVisible(false);
    fetchNui('spawn', { model });
  };

  // Star: the server stores favorites in the database and returns the updated list
  const toggleFavorite = async (e: MouseEvent, model: string) => {
    e.stopPropagation(); // so a click on the star does not trigger a spawn
    const updated = await fetchNui<string[]>('favorite', { model });
    if (updated) {
      setFavorites(updated);
    } else {
      // Browser development mode: there is no server, so toggle locally
      setFavorites((f) => (f.includes(model) ? f.filter((m) => m !== model) : [...f, model]));
    }
  };

  // Favorites come first, the order of the others stays the same
  const sorted = useMemo(
    () => [...cars].sort((a, b) => Number(favorites.includes(b)) - Number(favorites.includes(a))),
    [cars, favorites],
  );

  // Browser only: a button to reopen the window after closing it
  if (!visible) {
    return isInGame() ? null : (
      <button className="dev-open" onClick={() => setVisible(true)}>Open menu (dev)</button>
    );
  }

  return (
    <div className="panel">
      <header className="panel-header">
        <div>
          <span className="eyebrow">Garage</span>
          <h1>Vehicles</h1>
        </div>
        <button className="close" onClick={close} aria-label="Close">×</button>
      </header>

      <div className="grid">
        {sorted.map((model, i) => {
          const fav = favorites.includes(model);
          return (
            <button
              key={model}
              className="card"
              style={{ '--i': i } as CSSProperties}
              onClick={() => pick(model)}
            >
              <span
                className={`star${fav ? ' on' : ''}`}
                role="button"
                aria-label={fav ? 'Remove from favorites' : 'Add to favorites'}
                onClick={(e) => toggleFavorite(e, model)}
              >
                {fav ? '★' : '☆'}
              </span>
              <div className="stage">
                {!missing[model] && (
                  <img
                    className="car"
                    src={imageUrl(model)}
                    alt={label(model)}
                    draggable={false}
                    onError={() => setMissing((m) => ({ ...m, [model]: true }))}
                  />
                )}
              </div>
              <div className="info">
                <span className="card-name">{label(model)}</span>
                <span className="card-action">Spawn <i>→</i></span>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}
