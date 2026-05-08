const MARKER = "keskos-bottom-panel-v1";
const TOP_RESERVE_MARKER = "keskos-top-reserve-v1";
const LAUNCHER_WIDGET = "com.keskos.launcherbutton";
const TASKS_WIDGET = "org.kde.plasma.icontasks";
const CLIPBOARD_WIDGET = "org.kde.plasma.clipboard";
const WORKSPACE_WIDGET = "com.keskos.workspaceswitcher";
const LEGACY_PAGER_WIDGETS = ["org.kde.plasma.pager", "org.kde.plasma.activitypager"];
const WORKSPACE_WIDGET_CANDIDATES = [WORKSPACE_WIDGET].concat(LEGACY_PAGER_WIDGETS);
const BOTTOM_PANEL_HEIGHT = 48;
const WOLFI_TOGGLE_COMMAND = "bash -lc 'if [ -x \"$HOME/.local/bin/keskos-toggle-wolfi\" ]; then exec \"$HOME/.local/bin/keskos-toggle-wolfi\"; elif [ -x /usr/bin/keskos-toggle-wolfi ]; then exec /usr/bin/keskos-toggle-wolfi; elif [ -x /usr/local/bin/keskos-toggle-wolfi ]; then exec /usr/local/bin/keskos-toggle-wolfi; elif [ -x \"$HOME/.local/bin/keskos-launcher\" ]; then exec \"$HOME/.local/bin/keskos-launcher\" --mode main; elif [ -x /usr/local/bin/keskos-launcher ]; then exec /usr/local/bin/keskos-launcher --mode main; elif [ -x /usr/bin/keskos-launcher ]; then exec /usr/bin/keskos-launcher --mode main; else exit 1; fi'";

function arrayHas(items, value) {
    return items && items.indexOf(value) !== -1;
}

function widgetAvailable(widgetType) {
    return arrayHas(knownWidgetTypes, widgetType);
}

function firstExistingDesktopId(candidates) {
    for (let i = 0; i < candidates.length; ++i) {
        if (applicationPath(candidates[i])) {
            return candidates[i];
        }
    }

    return "";
}

function resolveBrowserDesktopId() {
    return defaultApplication("browser", true)
        || firstExistingDesktopId(["librewolf.desktop", "zen-browser.desktop", "zen.desktop", "brave-browser.desktop", "brave.desktop"])
        || "keskos-browser.desktop";
}

function resolveTerminalDesktopId() {
    return firstExistingDesktopId(["org.kde.konsole.desktop", "konsole.desktop"])
        || defaultApplication("terminal", true)
        || "keskos-terminal.desktop";
}

function resolveFilesDesktopId() {
    return firstExistingDesktopId(["org.kde.dolphin.desktop", "dolphin.desktop"])
        || defaultApplication("filemanager", true)
        || "keskos-files.desktop";
}

function resolveSettingsDesktopId() {
    return firstExistingDesktopId(["systemsettings.desktop", "kdesystemsettings.desktop"])
        || "systemsettings.desktop";
}

function resolveWorkspaceWidgetType() {
    for (let i = 0; i < WORKSPACE_WIDGET_CANDIDATES.length; ++i) {
        if (widgetAvailable(WORKSPACE_WIDGET_CANDIDATES[i])) {
            return WORKSPACE_WIDGET_CANDIDATES[i];
        }
    }

    return WORKSPACE_WIDGET;
}

function unique(items) {
    const seen = {};
    const result = [];

    for (let i = 0; i < items.length; ++i) {
        const item = items[i];
        if (!item || seen[item]) {
            continue;
        }

        seen[item] = true;
        result.push(item);
    }

    return result;
}

function asLauncher(desktopId) {
    return desktopId ? "applications:" + desktopId : "";
}

function defaultLaunchers(includeLauncherDesktop) {
    const launchers = [];

    if (includeLauncherDesktop) {
        launchers.push(asLauncher("keskos-launcher.desktop"));
    }

    launchers.push(asLauncher(resolveTerminalDesktopId()));
    launchers.push(asLauncher(resolveFilesDesktopId()));
    launchers.push(asLauncher(resolveBrowserDesktopId()));
    launchers.push(asLauncher(resolveSettingsDesktopId()));

    return unique(launchers);
}

function findManagedPanel(marker) {
    const panelList = panels();

    for (let i = 0; i < panelList.length; ++i) {
        const panel = panelList[i];
        panel.currentConfigGroup = new Array("General");

        if (panel.readConfig("keskosPanel", "") === marker) {
            return panel;
        }
    }

    return null;
}

function removeExistingPanels() {
    const panelList = panels();

    for (let i = 0; i < panelList.length; ++i) {
        try {
            panelList[i].remove();
        } catch (error) {
        }
    }
}

function panelNeedsReset(panel) {
    if (!panel) {
        return true;
    }

    if (panels().length !== 1) {
        return true;
    }

    if (screenCount <= 1 && panel.screen !== 0) {
        return true;
    }

    return false;
}

function findWidget(panel, widgetTypes) {
    for (let i = 0; i < panel.widgetIds.length; ++i) {
        const widget = panel.widgetById(panel.widgetIds[i]);

        if (widget && arrayHas(widgetTypes, widget.type)) {
            return widget;
        }
    }

    return null;
}

function removeWidgets(panel, widgetTypes) {
    for (let i = panel.widgetIds.length - 1; i >= 0; --i) {
        const widget = panel.widgetById(panel.widgetIds[i]);
        if (widget && arrayHas(widgetTypes, widget.type)) {
            widget.remove();
        }
    }
}

function clearPanelWidgets(panel) {
    for (let i = panel.widgetIds.length - 1; i >= 0; --i) {
        const widget = panel.widgetById(panel.widgetIds[i]);
        if (widget) {
            widget.remove();
        }
    }
}

function removeManagedPanel(marker) {
    const panel = findManagedPanel(marker);

    if (!panel) {
        return;
    }

    try {
        panel.remove();
    } catch (error) {
    }
}

function configureLauncher(widget) {
    if (!widget) {
        return;
    }

    widget.currentConfigGroup = new Array("General");
    widget.writeConfig("label", "KeskOS Launcher");
    widget.writeConfig("command", WOLFI_TOGGLE_COMMAND);
    widget.reloadConfig();
}

function configureTasks(widget, includeLauncherDesktop) {
    widget.currentConfigGroup = new Array("General");
    widget.writeConfig("launchers", defaultLaunchers(includeLauncherDesktop).join(","));
    widget.writeConfig("fill", true);
    widget.writeConfig("iconSpacing", 0);
    widget.writeConfig("indicateAudioStreams", false);
    widget.writeConfig("separateLaunchers", true);
    widget.reloadConfig();
}

function configurePager(widget) {
    if (!widget) {
        return;
    }

    widget.currentConfigGroup = new Array("General");
    widget.reloadConfig();
}

function configurePanel(panel) {
    try {
        panel.screen = 0;
    } catch (error) {
    }

    panel.location = "bottom";
    panel.lengthMode = "fill";
    panel.hiding = "none";
    panel.height = BOTTOM_PANEL_HEIGHT;

    try {
        panel.floating = false;
    } catch (error) {
    }

    try {
        panel.floatingApplets = false;
    } catch (error) {
    }

    try {
        panel.opacityMode = 1;
    } catch (error) {
    }

    panel.currentConfigGroup = new Array("General");
    panel.writeConfig("keskosPanel", MARKER);

    let launcher = null;
    if (widgetAvailable(LAUNCHER_WIDGET)) {
        launcher = findWidget(panel, [LAUNCHER_WIDGET]);
        if (!launcher) {
            launcher = panel.addWidget(LAUNCHER_WIDGET);
        }
    }

    let tasks = findWidget(panel, [TASKS_WIDGET]);
    if (!tasks) {
        tasks = panel.addWidget(TASKS_WIDGET);
    }

    let clipboard = null;
    if (widgetAvailable(CLIPBOARD_WIDGET)) {
        clipboard = findWidget(panel, [CLIPBOARD_WIDGET]);
        if (!clipboard) {
            clipboard = panel.addWidget(CLIPBOARD_WIDGET);
        }
    }

    const workspaceType = resolveWorkspaceWidgetType();
    let workspaceWidget = null;

    if (workspaceType === WORKSPACE_WIDGET && widgetAvailable(WORKSPACE_WIDGET)) {
        removeWidgets(panel, LEGACY_PAGER_WIDGETS);
        workspaceWidget = findWidget(panel, [WORKSPACE_WIDGET]);
        if (!workspaceWidget) {
            workspaceWidget = panel.addWidget(WORKSPACE_WIDGET);
        }
    } else {
        workspaceWidget = findWidget(panel, WORKSPACE_WIDGET_CANDIDATES);
        if (!workspaceWidget) {
            workspaceWidget = panel.addWidget(workspaceType);
        }
    }

    if (launcher) {
        launcher.index = 0;
    }

    tasks.index = launcher ? 1 : 0;
    if (clipboard) {
        clipboard.index = launcher ? 2 : 1;
    }
    workspaceWidget.index = launcher ? 3 : 2;

    configureLauncher(launcher);
    configureTasks(tasks, !launcher);
    if (clipboard) {
        clipboard.currentConfigGroup = new Array("General");
        clipboard.reloadConfig();
    }
    configurePager(workspaceWidget);

    const appletOrder = [];
    if (launcher) {
        appletOrder.push(String(launcher.id));
    }
    appletOrder.push(String(tasks.id));
    if (clipboard) {
        appletOrder.push(String(clipboard.id));
    }
    appletOrder.push(String(workspaceWidget.id));

    panel.currentConfigGroup = new Array("General");
    panel.writeConfig("AppletOrder", appletOrder.join(";"));
    panel.reloadConfig();
}

removeManagedPanel(TOP_RESERVE_MARKER);

let panel = findManagedPanel(MARKER);

if (panelNeedsReset(panel)) {
    removeExistingPanels();
    panel = new Panel;
}

configurePanel(panel);
