import discord
from discord import app_commands
from discord.ext import commands
import os
import subprocess
import json
import traceback
from dotenv import load_dotenv

load_dotenv()
TOKEN = os.getenv("DISCORD_BOT_TOKEN")
GUILD_ID = int(os.getenv("DISCORD_GUILD_ID"))
NAB6_IP = os.getenv("NAB6_HOST")
GIT_REPO_PATH = os.getenv("GIT_REPO_PATH")
BACKUP_SCRIPT = f"{GIT_REPO_PATH}/custom-scripts/ds920/ds920_backup.sh"

class HomeLabBot(commands.Bot):
    def __init__(self):
        intents = discord.Intents.default()
        super().__init__(command_prefix="!", intents=intents)

    async def setup_hook(self):
        guild = discord.Object(id=GUILD_ID)
        await self.tree.sync(guild=guild)
        print("✅ Slash-Commands wurden neu synchronisiert.")

bot = HomeLabBot()

@bot.event
async def on_ready():
    print(f"✅ Bot ist online als {bot.user}!")

@bot.tree.command(name="serverstatus", description="Zeigt den Systemstatus als hübschen Embed")
async def serverstatus(interaction: discord.Interaction):
    try:
        await interaction.response.defer()
        result = subprocess.run(["ssh", f"root@{NAB6_IP}", f"{MONITOR_SCRIPT} --manual"], capture_output=True, text=True, timeout=15)
        data = json.loads(result.stdout.strip())
        embed = discord.Embed(title="📊 HomeLab Systemstatus", color=0x00ffcc)
        embed.add_field(name="🕒 Uptime", value=data.get("uptime", "-"), inline=True)
        embed.add_field(name="🚦 CPU-Last", value=data.get("load", "-"), inline=True)
        embed.add_field(name="🧰 RAM", value=data.get("ram", "-"), inline=True)
        embed.add_field(name="📀 Speicher", value=data.get("disk", "-"), inline=True)
        embed.add_field(name="🔥 Temperatur", value=data.get("temp", "-"), inline=True)
        embed.add_field(name="🌐 IP", value=data.get("ip", "-"), inline=True)
        embed.add_field(name="🔌 Ping", value=data.get("ping", "-"), inline=True)
        embed.add_field(name="👤 SSH Logins", value=data.get("logins", "-"), inline=False)
        embed.add_field(name="🚀 Netzwerkgeräte", value=str(data.get("devices", "-")), inline=True)
        embed.add_field(name="📦 Updates", value=data.get("updates", "-"), inline=True)
        embed.add_field(name="💾 Backup", value=data.get("backup", "-"), inline=False)
        embed.add_field(name="🚨 Fehlerlogs", value=data.get("logs", "-"), inline=False)
        embed.add_field(name="🖥️ VS Code Remote", value=data.get("vscode", "-"), inline=True)
        embed.set_footer(text="HomeLabBot Statusreport")
        await interaction.followup.send(embed=embed)
    except Exception as e:
        traceback.print_exc()
        await interaction.followup.send(f"❌ Fehler beim Abrufen:\n```{e}```", ephemeral=True)

@bot.tree.command(name="nas-backup-start", description="Startet das NAS Backup Script")
async def nas_backup_start(interaction: discord.Interaction):
    await interaction.response.defer()
    try:
        check = subprocess.run(["ssh", f"root@{NAB6_IP}", f"pgrep -f {os.path.basename(BACKUP_SCRIPT)}"], capture_output=True, text=True)
        if check.stdout.strip():
            await interaction.followup.send("⚠️ Backup läuft bereits.")
            return
        subprocess.run(["ssh", f"root@{NAB6_IP}", f"nohup bash {BACKUP_SCRIPT} > /dev/null 2>&1 & disown"], check=True)
        await interaction.followup.send("🛡️ NAS Backup wurde gestartet.")
    except Exception as e:
        await interaction.followup.send(f"❌ Fehler beim Start:\n```{e}```", ephemeral=True)

@bot.tree.command(name="nas-backup-stop", description="Beendet ein laufendes NAS Backup Script")
async def nas_backup_stop(interaction: discord.Interaction):
    await interaction.response.defer()
    try:
        result = subprocess.run(["ssh", f"root@{NAB6_IP}", f"pkill -f {os.path.basename(BACKUP_SCRIPT)}"], capture_output=True, text=True)
        if result.returncode == 0:
            await interaction.followup.send("🛑 NAS Backup wurde gestoppt.")
        else:
            await interaction.followup.send("ℹ️ Kein laufendes Backup gefunden.")
    except Exception as e:
        await interaction.followup.send(f"❌ Fehler beim Stoppen:\n```{e}```", ephemeral=True)

@bot.tree.command(name="nas-backup-status", description="Zeigt aktuellen Backup-Status & letzte Logs")
async def nas_backup_status(interaction: discord.Interaction):
    await interaction.response.defer()
    try:
        check = subprocess.run(["ssh", f"root@{NAB6_IP}", f"pgrep -f {os.path.basename(BACKUP_SCRIPT)}"], capture_output=True, text=True)
        is_running = "🟢 Läuft gerade" if check.stdout.strip() else "🔴 Kein aktives Backup"
        cmd = 'ls -t /var/log/rclone-backups/*.log 2>/dev/null | head -n 1'
        logfile_result = subprocess.run(["ssh", f"root@{NAB6_IP}", cmd], capture_output=True, text=True)
        logfile = logfile_result.stdout.strip()
        log_tail = "Keine Logdatei gefunden."
        if logfile:
            tail_cmd = f"tail -n 15 {logfile}"
            log_tail_result = subprocess.run(["ssh", f"root@{NAB6_IP}", tail_cmd], capture_output=True, text=True)
            log_tail = f"📄 Letztes Logfile: `{os.path.basename(logfile)}`\n```{log_tail_result.stdout.strip()}```"
        await interaction.followup.send(f"{is_running}\n\n{log_tail}")
    except Exception as e:
        await interaction.followup.send(f"❌ Fehler beim Status:\n```{e}```", ephemeral=True)

bot.run(TOKEN)