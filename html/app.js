const app = document.getElementById('app');
const actionsEl = document.getElementById('actions');
const ordersEl = document.getElementById('orders');
const tradesEl = document.getElementById('trades');
const plateEl = document.getElementById('plate');
const gradeEl = document.getElementById('grade');
const repEl = document.getElementById('rep');
const levelEl = document.getElementById('level');

const ACTIONS = [
    ['ScanVehicle', 'SCAN', 'First step'],
    ['SearchGlovebox', 'GLOVEBOX', 'Search'],
    ['SearchTrunk', 'TRUNK', 'Search'],
    ['StripEngine', 'ENGINE BAY', 'Strip'],
    ['StripBrakes', 'WHEELS / BRAKES', 'Strip'],
    ['TorchVehicle', 'TORCH', 'Safe fire'],
    ['CleanStrip', 'CLEAN STRIP', 'Parts'],
    ['PartOut', 'PART-OUT', 'Parts'],
    ['CrushVehicle', 'CRUSH', 'Finish'],
    ['QuickDump', 'QUICK DUMP', 'Finish']
];

let lastData = {};
let lastVehicle = {};

function nui(name, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(data)
    });
}

function closeUi() {
    app.classList.add('hidden');
    nui('close');
}

function hasVehicle(vehicle) {
    return vehicle && vehicle.plate && String(vehicle.plate).trim().length > 0;
}

function statusFor(name, data, vehicle) {
    if (!hasVehicle(vehicle)) return 'Locked';

    const done = data.actions && data.actions[name];
    const scanned = data.actions && data.actions.ScanVehicle;

    if (done) return 'Done';
    if (name !== 'ScanVehicle' && !scanned) return 'Locked';
    if (data.crushed) return 'Locked';

    return 'Ready';
}

function renderTrades(trades) {
    tradesEl.innerHTML = '';

    trades = trades || [];

    if (!trades.length) {
        tradesEl.innerHTML = '<div class="order"><span>None</span><span>-</span></div>';
        return;
    }

    trades.forEach(trade => {
        const row = document.createElement('div');
        row.className = 'trade';

        const disabled = (trade.count || 0) <= 0;

        row.innerHTML = `
            <div>
                <h3>${trade.label || trade.item} <span>(${trade.count || 0})</span></h3>
                <p>${(trade.outputs || []).join(', ')}</p>
            </div>
            <button ${disabled ? 'disabled' : ''}>Trade</button>
        `;

        row.querySelector('button').addEventListener('click', () => {
            if (disabled) return;

            nui('trade', {
                item: trade.item
            })
                .then(r => r.json())
                .then(res => {
                    if (res && res.trades) {
                        renderTrades(res.trades);
                    }
                });
        });

        tradesEl.appendChild(row);
    });
}

function render(data, vehicle) {
    lastData = data || {};
    lastVehicle = vehicle || {};

    app.classList.remove('hidden');

    plateEl.textContent = hasVehicle(vehicle) ? `PLATE ${vehicle.plate}` : 'NO VEHICLE';
    gradeEl.textContent = data.grade || '-';
    repEl.textContent = data.rep || 0;
    levelEl.textContent = data.level || 'Rookie';

    actionsEl.innerHTML = '';

    ACTIONS.forEach(([name, title, note]) => {
        const status = statusFor(name, data, vehicle);
        const button = document.createElement('button');

        button.className = `card ${status === 'Done' ? 'done' : ''} ${status === 'Locked' ? 'locked' : ''}`;

        button.innerHTML = `
            <h3>${title}</h3>
            <p>${note}</p>
            <p class="status">${status}</p>
        `;

        button.addEventListener('click', () => {
            if (status === 'Locked' || status === 'Done') return;

            app.classList.add('hidden');

            nui('action', {
                actionName: name
            });
        });

        actionsEl.appendChild(button);
    });

    renderTrades(data.trades || []);

    ordersEl.innerHTML = '';

    const orders = data.orders || [];

    if (!orders.length) {
        ordersEl.innerHTML = '<div class="order"><span>None</span><span>-</span></div>';
        return;
    }

    orders.forEach(order => {
        const row = document.createElement('div');
        row.className = 'order';

        row.innerHTML = `
            <span>${order.label}</span>
            <span>${order.completed ? 'Done' : `${order.progress}/${order.amount}`}</span>
        `;

        ordersEl.appendChild(row);
    });
}

document.getElementById('close').addEventListener('click', closeUi);

document.addEventListener('keydown', e => {
    if (e.key === 'Escape') closeUi();
});

window.addEventListener('message', event => {
    const msg = event.data || {};

    if (msg.action === 'open') {
        render(msg.data || {}, msg.vehicle || {});
    }

    if (msg.action === 'trades') {
        renderTrades(msg.trades || []);
    }

    if (msg.action === 'close') {
        app.classList.add('hidden');
    }
});
