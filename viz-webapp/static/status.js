'use strict';

const tableBody = document.getElementById('status-body');
const lastUpdatedEl = document.getElementById('last-updated');
const formatter = new Intl.NumberFormat('en-US');

function formatBytes(bytes) {
    if (bytes === null || bytes === undefined) return '0 B';
    if (bytes === 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    const exponent = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1);
    const value = bytes / Math.pow(1024, exponent);
    return `${value.toFixed(exponent === 0 ? 0 : 2)} ${units[exponent]}`;
}

function renderRow(name, stats) {
    const statusClass = stats.status === 'running' ? 'status-chip running' : 'status-chip error';
    const statusText = stats.status === 'running' ? 'Running' : 'Unavailable';
    const errorDetail = stats.error ? `<div class="status-error">${stats.error}</div>` : '';

    return `
        <tr>
            <td class="name-cell">${name}</td>
            <td>
                <span class="${statusClass}">${statusText}</span>
                ${errorDetail}
            </td>
            <td>${formatBytes(stats.rx_bytes)}</td>
            <td>${formatBytes(stats.tx_bytes)}</td>
            <td>${formatter.format(stats.rx_packets || 0)}</td>
            <td>${formatter.format(stats.tx_packets || 0)}</td>
        </tr>
    `;
}

async function loadStatus() {
    try {
        const response = await fetch('/api/stats');
        if (!response.ok) throw new Error(`Server responded with ${response.status}`);
        const data = await response.json();

        if (!data || Object.keys(data).length === 0) {
            tableBody.innerHTML = '<tr><td colspan="6" class="loading">No containers found.</td></tr>';
            return;
        }

        const rows = Object.entries(data)
            .map(([name, stats]) => renderRow(name, stats))
            .join('');

        tableBody.innerHTML = rows;
        lastUpdatedEl.textContent = `Last updated: ${new Date().toLocaleTimeString()}`;
    } catch (error) {
        console.error('Failed to load container status', error);
        tableBody.innerHTML = `
            <tr>
                <td colspan="6" class="error">
                    Unable to load container status. ${error.message}
                </td>
            </tr>
        `;
    }
}

loadStatus();
setInterval(loadStatus, 3000);
