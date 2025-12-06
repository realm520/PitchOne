package styles

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/lipgloss"
)

// PitchOne ASCII Logo
const logo = `
  ____  _ _       _      ___
 |  _ \(_) |_ ___| |__  / _ \ _ __   ___
 | |_) | | __/ __| '_ \| | | | '_ \ / _ \
 |  __/| | || (__| | | | |_| | | | |  __/
 |_|   |_|\__\___|_| |_|\___/|_| |_|\___|
`

// 简版 Logo
const logoSmall = `⚽ PitchOne`

// RenderLogo 渲染大 Logo
func RenderLogo() string {
	logoStyle := lipgloss.NewStyle().
		Foreground(Primary).
		Bold(true)
	return logoStyle.Render(logo)
}

// RenderSmallLogo 渲染小 Logo
func RenderSmallLogo() string {
	return LogoStyle.Render(logoSmall)
}

// RenderBanner 渲染启动横幅
func RenderBanner(version, network string, chainID int64) string {
	// Logo
	logoStyled := lipgloss.NewStyle().
		Foreground(Primary).
		Bold(true).
		Render(logo)

	// 版本和网络信息
	versionText := fmt.Sprintf("v%s", version)
	versionStyled := lipgloss.NewStyle().
		Foreground(TextMuted).
		Render(versionText)

	networkBadge := RenderNetworkBadge(network)

	chainText := fmt.Sprintf("Chain ID: %d", chainID)
	chainStyled := lipgloss.NewStyle().
		Foreground(TextDim).
		Render(chainText)

	// 组合信息行
	infoLine := lipgloss.JoinHorizontal(
		lipgloss.Center,
		versionStyled,
		"  │  ",
		networkBadge,
		"  │  ",
		chainStyled,
	)

	// 分隔线
	divider := RenderDivider(50)

	return lipgloss.JoinVertical(
		lipgloss.Left,
		logoStyled,
		infoLine,
		divider,
	)
}

// RenderHeader 渲染页面标题
func RenderHeader(title string) string {
	// 小 Logo + 标题
	header := lipgloss.JoinHorizontal(
		lipgloss.Center,
		LogoStyle.Render(logoSmall),
		"  ",
		TitleStyle.Render(title),
	)

	return header
}

// RenderPageTitle 渲染命令页面标题
func RenderPageTitle(title, subtitle string) string {
	var sb strings.Builder

	// 标题
	sb.WriteString(TitleStyle.Render(title))
	sb.WriteString("\n")

	// 副标题
	if subtitle != "" {
		sb.WriteString(SubtitleStyle.Render(subtitle))
		sb.WriteString("\n")
	}

	// 分隔线
	sb.WriteString(RenderDivider(len(title) + 4))
	sb.WriteString("\n")

	return sb.String()
}

// RenderSuccess 渲染成功消息
func RenderSuccess(message string) string {
	icon := "✓"
	return SuccessStyle.Render(icon + " " + message)
}

// RenderError 渲染错误消息
func RenderError(message string) string {
	icon := "✗"
	return ErrorStyle.Render(icon + " " + message)
}

// RenderWarning 渲染警告消息
func RenderWarning(message string) string {
	icon := "⚠"
	return WarningStyle.Render(icon + " " + message)
}

// RenderInfo 渲染信息消息
func RenderInfo(message string) string {
	icon := "ℹ"
	return InfoStyle.Render(icon + " " + message)
}

// RenderProgress 渲染进度条
func RenderProgress(current, total int, width int) string {
	if total <= 0 {
		total = 1
	}
	percentage := float64(current) / float64(total)
	filled := int(percentage * float64(width))
	if filled > width {
		filled = width
	}

	bar := strings.Repeat("█", filled) + strings.Repeat("░", width-filled)
	percentText := fmt.Sprintf("%3.0f%%", percentage*100)

	barStyle := lipgloss.NewStyle().Foreground(Primary)
	percentStyle := lipgloss.NewStyle().Foreground(TextMuted)

	return barStyle.Render(bar) + " " + percentStyle.Render(percentText)
}

// RenderSpinner 渲染加载动画帧
func RenderSpinner(frame int) string {
	spinners := []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
	idx := frame % len(spinners)
	return LogoStyle.Render(spinners[idx])
}

// RenderStat 渲染统计数据
func RenderStat(label, value string) string {
	labelStyled := lipgloss.NewStyle().
		Foreground(TextMuted).
		Width(20).
		Render(label)

	valueStyled := lipgloss.NewStyle().
		Foreground(Primary).
		Bold(true).
		Render(value)

	return labelStyled + valueStyled
}

// RenderStatCard 渲染统计卡片
func RenderStatCard(title string, stats map[string]string, keys []string) string {
	var content strings.Builder

	for _, key := range keys {
		value := stats[key]
		content.WriteString(RenderStat(key, value))
		content.WriteString("\n")
	}

	return RenderCard(title, content.String())
}
