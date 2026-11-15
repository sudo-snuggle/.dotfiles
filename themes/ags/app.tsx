import { App, Astal, Gtk, Gdk } from "astal/gtk4"
import { Variable } from "astal"
import { execAsync } from "astal/process"
import style from "./style.scss"

interface Tile {
  name: string
  subtitle: string
  icon: string
  cmd: string
}

const tiles: Tile[] = [
  {
    name: "YouTube",
    subtitle: "VacuumTube TV",
    icon: "video-display-symbolic",
    cmd: "flatpak run rocks.shy.VacuumTube --fullscreen",
  },
  {
    name: "Music",
    subtitle: "NaviBeat",
    icon: "audio-x-generic-symbolic",
    cmd: "appimage-run /home/yasiru/Downloads/NaviBeat-linux-x86_64.AppImage",
  },
  {
    name: "Terminal",
    subtitle: "Foot Shell",
    icon: "utilities-terminal-symbolic",
    cmd: "foot",
  },
]

const selected = Variable(0)

function launch(index: number) {
  execAsync(["bash", "-c", tiles[index].cmd]).catch(console.error)
}

function TvLauncher() {
  return (
    <window
      name="tv-launcher"
      visible
      anchor={
        Astal.WindowAnchor.TOP |
        Astal.WindowAnchor.BOTTOM |
        Astal.WindowAnchor.LEFT |
        Astal.WindowAnchor.RIGHT
      }
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.EXCLUSIVE}
      application={App}
      onKeyPressed={(_, keyval) => {
        if (keyval === Gdk.KEY_Right) {
          selected.set((selected.get() + 1) % tiles.length)
        } else if (keyval === Gdk.KEY_Left) {
          selected.set((selected.get() - 1 + tiles.length) % tiles.length)
        } else if (keyval === Gdk.KEY_Return || keyval === Gdk.KEY_KP_Enter) {
          launch(selected.get())
        }
      }}
    >
      <box
        cssClasses={["backdrop"]}
        valign={Gtk.Align.CENTER}
        halign={Gtk.Align.CENTER}
        spacing={36}
      >
        {tiles.map((tile, i) => (
          <button
            cssClasses={selected((s) => (s === i ? ["tile", "active"] : ["tile"]))}
            onClicked={() => {
              selected.set(i)
              launch(i)
            }}
          >
            <box vertical valign={Gtk.Align.CENTER} halign={Gtk.Align.CENTER} spacing={16}>
              <image iconName={tile.icon} pixelSize={84} />
              <label cssClasses={["title"]} label={tile.name} />
              <label cssClasses={["subtitle"]} label={tile.subtitle} />
            </box>
          </button>
        ))}
      </box>
    </window>
  )
}

App.start({
  css: style,
  main() {
    TvLauncher()
  },
})