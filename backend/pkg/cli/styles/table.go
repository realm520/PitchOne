package styles

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
)

// Table 美化表格
type Table struct {
	headers []string
	rows    [][]string
	widths  []int
}

// NewTable 创建新表格
func NewTable() *Table {
	return &Table{
		headers: []string{},
		rows:    [][]string{},
		widths:  []int{},
	}
}

// SetHeaders 设置表头
func (t *Table) SetHeaders(headers []string) {
	t.headers = headers
	t.widths = make([]int, len(headers))
	for i, h := range headers {
		t.widths[i] = len(h)
	}
}

// AddRow 添加一行
func (t *Table) AddRow(row []string) {
	t.rows = append(t.rows, row)
	for i, cell := range row {
		if i < len(t.widths) && len(cell) > t.widths[i] {
			t.widths[i] = len(cell)
		}
	}
}

// AddRows 添加多行
func (t *Table) AddRows(rows [][]string) {
	for _, row := range rows {
		t.AddRow(row)
	}
}

// Render 渲染表格
func (t *Table) Render() string {
	if len(t.headers) == 0 {
		return ""
	}

	var sb strings.Builder

	// 计算总宽度
	totalWidth := 0
	for _, w := range t.widths {
		totalWidth += w + 3 // padding + separator
	}
	totalWidth += 1 // 最后的边框

	// 上边框
	sb.WriteString(t.renderTopBorder())
	sb.WriteString("\n")

	// 表头
	sb.WriteString(t.renderHeaderRow())
	sb.WriteString("\n")

	// 表头分隔线
	sb.WriteString(t.renderHeaderSeparator())
	sb.WriteString("\n")

	// 数据行
	for i, row := range t.rows {
		sb.WriteString(t.renderDataRow(row, i%2 == 0))
		sb.WriteString("\n")
	}

	// 下边框
	sb.WriteString(t.renderBottomBorder())

	return sb.String()
}

func (t *Table) renderTopBorder() string {
	var parts []string
	for i, w := range t.widths {
		if i == 0 {
			parts = append(parts, "╭"+strings.Repeat("─", w+2))
		} else {
			parts = append(parts, "┬"+strings.Repeat("─", w+2))
		}
	}
	return DividerStyle.Render(strings.Join(parts, "") + "╮")
}

func (t *Table) renderBottomBorder() string {
	var parts []string
	for i, w := range t.widths {
		if i == 0 {
			parts = append(parts, "╰"+strings.Repeat("─", w+2))
		} else {
			parts = append(parts, "┴"+strings.Repeat("─", w+2))
		}
	}
	return DividerStyle.Render(strings.Join(parts, "") + "╯")
}

func (t *Table) renderHeaderSeparator() string {
	var parts []string
	for i, w := range t.widths {
		if i == 0 {
			parts = append(parts, "├"+strings.Repeat("─", w+2))
		} else {
			parts = append(parts, "┼"+strings.Repeat("─", w+2))
		}
	}
	return DividerStyle.Render(strings.Join(parts, "") + "┤")
}

func (t *Table) renderHeaderRow() string {
	var cells []string
	for i, h := range t.headers {
		cell := TableHeaderStyle.Width(t.widths[i]).Render(h)
		cells = append(cells, cell)
	}
	border := DividerStyle.Render("│")
	return border + " " + strings.Join(cells, " "+border+" ") + " " + border
}

func (t *Table) renderDataRow(row []string, even bool) string {
	var cells []string
	style := TableCellStyle
	if even {
		style = style.Inherit(TableRowEvenStyle)
	}

	for i, cell := range row {
		width := 10
		if i < len(t.widths) {
			width = t.widths[i]
		}

		// 根据内容类型应用不同样式
		styledCell := t.styleCell(cell, width)
		cells = append(cells, styledCell)
	}

	border := DividerStyle.Render("│")
	return border + " " + strings.Join(cells, " "+border+" ") + " " + border
}

func (t *Table) styleCell(cell string, width int) string {
	// 检测特殊内容并应用样式
	cellStyle := TableCellStyle.Width(width)

	// 检测状态
	switch cell {
	case "Open":
		return StatusOpenStyle.Width(width).Render(cell)
	case "Locked":
		return StatusLockedStyle.Width(width).Render(cell)
	case "Resolved":
		return StatusResolvedStyle.Width(width).Render(cell)
	case "Finalized":
		return StatusFinalizedStyle.Width(width).Render(cell)
	case "Cancelled":
		return StatusCancelledStyle.Width(width).Render(cell)
	case "Yes":
		return SuccessStyle.Width(width).Render(cell)
	case "No":
		return ErrorStyle.Width(width).Render(cell)
	}

	// 检测地址（0x开头）
	if strings.HasPrefix(cell, "0x") {
		return AddressStyle.Width(width).Render(cell)
	}

	// 检测金额（包含 USDC）
	if strings.Contains(cell, "USDC") || strings.Contains(cell, "pLP") {
		return AmountStyle.Width(width).Render(cell)
	}

	// 检测百分比
	if strings.HasSuffix(cell, "%") || strings.Contains(cell, "bps") {
		return PercentStyle.Width(width).Render(cell)
	}

	return cellStyle.Render(cell)
}

// RenderSimpleTable 渲染简单的键值表格（用于 info 类命令）
func RenderSimpleTable(data map[string]string, title string) string {
	var sb strings.Builder

	// 标题
	if title != "" {
		sb.WriteString(TitleStyle.Render(title))
		sb.WriteString("\n")
		sb.WriteString(RenderDivider(len(title) + 4))
		sb.WriteString("\n\n")
	}

	// 计算最大键宽度
	maxKeyWidth := 0
	for key := range data {
		if len(key) > maxKeyWidth {
			maxKeyWidth = len(key)
		}
	}

	// 渲染键值对
	keyStyle := KeyStyle.Width(maxKeyWidth + 2)
	for key, value := range data {
		// 根据值类型选择样式
		valueStyled := styleValue(value)
		sb.WriteString(keyStyle.Render(key))
		sb.WriteString(valueStyled)
		sb.WriteString("\n")
	}

	return sb.String()
}

// RenderOrderedTable 渲染有序的键值表格
func RenderOrderedTable(keys []string, data map[string]string, title string) string {
	var sb strings.Builder

	// 标题
	if title != "" {
		sb.WriteString(TitleStyle.Render(title))
		sb.WriteString("\n")
		sb.WriteString(RenderDivider(len(title) + 4))
		sb.WriteString("\n\n")
	}

	// 计算最大键宽度
	maxKeyWidth := 0
	for _, key := range keys {
		if len(key) > maxKeyWidth {
			maxKeyWidth = len(key)
		}
	}

	// 渲染键值对
	keyStyle := KeyStyle.Width(maxKeyWidth + 2)
	for _, key := range keys {
		value := data[key]
		valueStyled := styleValue(value)
		sb.WriteString(keyStyle.Render(key))
		sb.WriteString(valueStyled)
		sb.WriteString("\n")
	}

	return sb.String()
}

func styleValue(value string) string {
	// 检测地址
	if strings.HasPrefix(value, "0x") {
		return AddressStyle.Render(value)
	}

	// 检测金额
	if strings.Contains(value, "USDC") || strings.Contains(value, "pLP") {
		return AmountStyle.Render(value)
	}

	// 检测百分比
	if strings.HasSuffix(value, "%") {
		return PercentStyle.Render(value)
	}

	// 检测状态
	switch value {
	case "Open", "Yes", "Active":
		return SuccessStyle.Render(value)
	case "Locked":
		return WarningStyle.Render(value)
	case "Cancelled", "No", "Inactive":
		return ErrorStyle.Render(value)
	}

	return ValueStyle.Render(value)
}

// RenderCard 渲染卡片
func RenderCard(title, content string) string {
	titleStyled := TitleStyle.Render(title)
	return CardStyle.Render(titleStyled + "\n" + content)
}

// RenderBox 渲染盒子
func RenderBox(content string) string {
	return BoxStyle.Render(content)
}

// RenderNetworkBadge 渲染网络标签
func RenderNetworkBadge(network string) string {
	var bg lipgloss.Color
	switch network {
	case "mainnet":
		bg = Success
	case "testnet":
		bg = Warning
	default:
		bg = Accent
	}
	style := NetworkBadgeStyle.Background(bg)
	return style.Render(network)
}

// RenderHeader 渲染页面标题（带 logo）
func RenderHeader(title, network string, chainID int64) string {
	logo := LogoStyle.Render("⚽ PitchOne")
	badge := RenderNetworkBadge(network)

	header := lipgloss.JoinHorizontal(
		lipgloss.Center,
		logo,
		"  ",
		badge,
	)

	subtitle := SubtitleStyle.Render("Chain ID: " + string(rune(chainID)))

	return lipgloss.JoinVertical(
		lipgloss.Left,
		header,
		TitleStyle.Render(title),
	)
}
