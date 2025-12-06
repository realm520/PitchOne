package output

import (
	"encoding/json"
	"io"
)

// JSONFormatter JSON 格式化器
type JSONFormatter struct {
	writer  io.Writer
	headers []string
	rows    [][]string
}

// NewJSONFormatter 创建 JSON 格式化器
func NewJSONFormatter(writer io.Writer) *JSONFormatter {
	return &JSONFormatter{
		writer: writer,
		rows:   make([][]string, 0),
	}
}

// SetHeader 设置表头
func (f *JSONFormatter) SetHeader(headers []string) {
	f.headers = headers
}

// AddRow 添加行
func (f *JSONFormatter) AddRow(row []string) {
	f.rows = append(f.rows, row)
}

// AddRows 批量添加行
func (f *JSONFormatter) AddRows(rows [][]string) {
	f.rows = append(f.rows, rows...)
}

// Render 渲染输出
func (f *JSONFormatter) Render() error {
	// 转换为对象数组
	var result []map[string]string

	for _, row := range f.rows {
		item := make(map[string]string)
		for i, header := range f.headers {
			if i < len(row) {
				item[header] = row[i]
			}
		}
		result = append(result, item)
	}

	encoder := json.NewEncoder(f.writer)
	encoder.SetIndent("", "  ")
	return encoder.Encode(result)
}

// RenderMap 渲染键值对
func (f *JSONFormatter) RenderMap(data map[string]string, title string) error {
	result := data
	if title != "" {
		wrapper := map[string]interface{}{
			"title": title,
			"data":  data,
		}
		encoder := json.NewEncoder(f.writer)
		encoder.SetIndent("", "  ")
		return encoder.Encode(wrapper)
	}

	encoder := json.NewEncoder(f.writer)
	encoder.SetIndent("", "  ")
	return encoder.Encode(result)
}

// RenderRaw 渲染任意对象
func (f *JSONFormatter) RenderRaw(data interface{}) error {
	encoder := json.NewEncoder(f.writer)
	encoder.SetIndent("", "  ")
	return encoder.Encode(data)
}
