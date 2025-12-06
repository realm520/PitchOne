package styles

import (
	"github.com/charmbracelet/lipgloss"
)

// PitchOne 品牌色
var (
	// 主色调 - 蓝绿色系
	Primary     = lipgloss.Color("#00D4AA")
	PrimaryDark = lipgloss.Color("#00A88A")

	// 强调色 - 紫色系
	Accent     = lipgloss.Color("#7C3AED")
	AccentDark = lipgloss.Color("#5B21B6")

	// 状态色
	Success = lipgloss.Color("#10B981")
	Warning = lipgloss.Color("#F59E0B")
	Error   = lipgloss.Color("#EF4444")
	Info    = lipgloss.Color("#3B82F6")

	// 中性色
	Text       = lipgloss.Color("#E5E7EB")
	TextMuted  = lipgloss.Color("#9CA3AF")
	TextDim    = lipgloss.Color("#6B7280")
	Background = lipgloss.Color("#111827")
	Border     = lipgloss.Color("#374151")

	// 表格色
	TableHeader = lipgloss.Color("#6366F1")
	TableRow    = lipgloss.Color("#1F2937")
	TableAlt    = lipgloss.Color("#111827")
)

// 预定义样式
var (
	// Logo 样式
	LogoStyle = lipgloss.NewStyle().
			Foreground(Primary).
			Bold(true)

	// 标题样式
	TitleStyle = lipgloss.NewStyle().
			Foreground(Primary).
			Bold(true).
			MarginBottom(1)

	// 副标题样式
	SubtitleStyle = lipgloss.NewStyle().
			Foreground(TextMuted).
			Italic(true)

	// 分隔线
	DividerStyle = lipgloss.NewStyle().
			Foreground(Border)

	// 成功消息
	SuccessStyle = lipgloss.NewStyle().
			Foreground(Success).
			Bold(true)

	// 警告消息
	WarningStyle = lipgloss.NewStyle().
			Foreground(Warning).
			Bold(true)

	// 错误消息
	ErrorStyle = lipgloss.NewStyle().
			Foreground(Error).
			Bold(true)

	// 信息消息
	InfoStyle = lipgloss.NewStyle().
			Foreground(Info)

	// 键值对 - 键
	KeyStyle = lipgloss.NewStyle().
			Foreground(TextMuted).
			Width(20)

	// 键值对 - 值
	ValueStyle = lipgloss.NewStyle().
			Foreground(Text)

	// 高亮值（金额、地址等）
	HighlightStyle = lipgloss.NewStyle().
			Foreground(Primary).
			Bold(true)

	// 地址样式
	AddressStyle = lipgloss.NewStyle().
			Foreground(Accent)

	// 金额样式
	AmountStyle = lipgloss.NewStyle().
			Foreground(Success)

	// 百分比样式
	PercentStyle = lipgloss.NewStyle().
			Foreground(Info)

	// 状态样式 - Open
	StatusOpenStyle = lipgloss.NewStyle().
			Foreground(Success).
			Bold(true)

	// 状态样式 - Locked
	StatusLockedStyle = lipgloss.NewStyle().
			Foreground(Warning).
			Bold(true)

	// 状态样式 - Resolved
	StatusResolvedStyle = lipgloss.NewStyle().
			Foreground(Info).
			Bold(true)

	// 状态样式 - Finalized
	StatusFinalizedStyle = lipgloss.NewStyle().
				Foreground(TextMuted).
				Bold(true)

	// 状态样式 - Cancelled
	StatusCancelledStyle = lipgloss.NewStyle().
				Foreground(Error).
				Bold(true)

	// 表格边框样式
	TableBorder = lipgloss.RoundedBorder()

	// 表格标题行样式
	TableHeaderStyle = lipgloss.NewStyle().
				Foreground(TableHeader).
				Bold(true).
				Padding(0, 1)

	// 表格单元格样式
	TableCellStyle = lipgloss.NewStyle().
			Foreground(Text).
			Padding(0, 1)

	// 表格行样式（偶数行）
	TableRowEvenStyle = lipgloss.NewStyle().
				Background(TableRow)

	// 表格行样式（奇数行）
	TableRowOddStyle = lipgloss.NewStyle().
				Background(TableAlt)

	// 盒子样式
	BoxStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(Border).
			Padding(1, 2)

	// 卡片样式
	CardStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(Primary).
			Padding(1, 2).
			MarginBottom(1)

	// 网络标签样式
	NetworkBadgeStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#FFFFFF")).
				Background(Accent).
				Padding(0, 1).
				Bold(true)

	// 命令帮助样式
	HelpKeyStyle = lipgloss.NewStyle().
			Foreground(Primary).
			Bold(true)

	// 命令描述样式
	HelpDescStyle = lipgloss.NewStyle().
			Foreground(TextMuted)
)

// GetStatusStyle 根据状态获取对应样式
func GetStatusStyle(status string) lipgloss.Style {
	switch status {
	case "Open":
		return StatusOpenStyle
	case "Locked":
		return StatusLockedStyle
	case "Resolved":
		return StatusResolvedStyle
	case "Finalized":
		return StatusFinalizedStyle
	case "Cancelled":
		return StatusCancelledStyle
	default:
		return lipgloss.NewStyle().Foreground(TextMuted)
	}
}

// RenderDivider 渲染分隔线
func RenderDivider(width int) string {
	line := ""
	for i := 0; i < width; i++ {
		line += "─"
	}
	return DividerStyle.Render(line)
}

// RenderKeyValue 渲染键值对
func RenderKeyValue(key, value string) string {
	return KeyStyle.Render(key) + ValueStyle.Render(value)
}

// RenderKeyValueHighlight 渲染高亮键值对
func RenderKeyValueHighlight(key, value string) string {
	return KeyStyle.Render(key) + HighlightStyle.Render(value)
}
