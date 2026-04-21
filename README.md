# Daogame

Вертикальная mobile xianxia RPG / idle cultivation game на Godot 4.

## Что внутри
- стартовый каркас проекта под Godot 4.x
- вертикальный lobby screen в стиле jade/gold xianxia UI
- экран культивации v1
- экран персонажа v1
- экран инвентаря v1
- autoload-сервисы для bootstrap / routing / player state / config loading
- mock-данные и JSON-конфиги

## Структура
- `scenes/` — экраны и UI-сцены
- `scripts/` — код приложения
- `data/configs/` — data-driven конфиги
- `data/mock/` — мок-профиль игрока
- `docs/` — документация проекта

## Запуск
1. Открой папку проекта в Godot 4.
2. Проверь autoload singleton'ы в `project.godot`.
3. Запусти проект — откроется bootstrap, затем lobby.
4. Навигация:
   - Культивация -> экран культивации
   - Персонаж -> экран персонажа
   - Рюкзак -> экран инвентаря
   - Дом / Орден / История -> пока заглушки

## Следующий шаг
1. Залить в GitHub.
2. Проверить запуск в Godot.
3. После этого можно наращивать:
   - data binding UI
   - battle vertical slice
   - idle rewards
   - save/load
   - backend stub
