package handlers

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ledongthuc/pdf"
)

const uploadDir = "./uploads"

func init() {
	// Create uploads directory if it doesn't exist
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		log.Printf("Error creating upload directory: %v\n", err)
	}
}

func extractPDFContent(filePath string) (string, error) {
	f, r, err := pdf.Open(filePath)
	if err != nil {
		return "", fmt.Errorf("error opening PDF: %v", err)
	}
	defer f.Close()

	var content strings.Builder
	totalPage := r.NumPage()

	for pageIndex := 1; pageIndex <= totalPage; pageIndex++ {
		p := r.Page(pageIndex)
		if p.V.IsNull() {
			continue
		}

		text, err := p.GetPlainText(nil)
		if err != nil {
			log.Printf("Error extracting text from page %d: %v", pageIndex, err)
			continue
		}
		content.WriteString(fmt.Sprintf("\n--- Page %d ---\n", pageIndex))
		content.WriteString(text)
	}

	return content.String(), nil
}

func searchInContent(content, query string) string {
	query = strings.ToLower(query)
	content = strings.ToLower(content)
	
	var result strings.Builder
	result.WriteString("🔍 Search Results:\n\n")

	// Split content into lines for better matching
	lines := strings.Split(content, "\n")
	
	// Search for exact matches first
	for i, line := range lines {
		if strings.Contains(line, query) {
			// Get some context (previous and next lines)
			start := max(0, i-2)
			end := min(len(lines), i+3)
			
			result.WriteString(fmt.Sprintf("Found in context:\n"))
			for j := start; j < end; j++ {
				if j == i {
					result.WriteString(fmt.Sprintf("→ %s\n", lines[j]))
				} else {
					result.WriteString(fmt.Sprintf("  %s\n", lines[j]))
				}
			}
			result.WriteString("\n")
		}
	}

	if result.Len() == 0 {
		result.WriteString("No exact matches found. Try different keywords or check the spelling.\n")
	}

	return result.String()
}

func processCommand(command string, fileInfo os.FileInfo, filePath string) string {
	command = strings.ToLower(command)
	
	// Extract key phrases from command
	isNotes := strings.Contains(command, "notes") || strings.Contains(command, "summary")
	isContent := strings.Contains(command, "content") || strings.Contains(command, "what is in")
	isDetails := strings.Contains(command, "details") || strings.Contains(command, "information")
	isSize := strings.Contains(command, "size") || strings.Contains(command, "how big")
	isType := strings.Contains(command, "type") || strings.Contains(command, "format")
	isSearch := strings.Contains(command, "search") || strings.Contains(command, "find")

	var response strings.Builder

	// Handle different command types
	switch {
	case isSearch:
		// Extract search query from command
		query := strings.TrimPrefix(command, "search")
		query = strings.TrimPrefix(query, "find")
		query = strings.TrimSpace(query)
		
		if query == "" {
			response.WriteString("❌ Please provide a search term. Example: 'search philosophy' or 'find education'\n")
			break
		}

		// For PDF files, search in content
		if strings.HasSuffix(strings.ToLower(filePath), ".pdf") {
			content, err := extractPDFContent(filePath)
			if err != nil {
				response.WriteString(fmt.Sprintf("❌ Error reading PDF: %v\n", err))
				break
			}
			response.WriteString(searchInContent(content, query))
		} else {
			response.WriteString("❌ Content search is only available for PDF files\n")
		}

	case isNotes:
		response.WriteString("📝 Notes about the file:\n")
		response.WriteString(fmt.Sprintf("- This is a %s file\n", filepath.Ext(filePath)))
		response.WriteString(fmt.Sprintf("- Created on: %s\n", fileInfo.ModTime().Format("January 2, 2006")))
		response.WriteString(fmt.Sprintf("- File size: %.2f MB\n", float64(fileInfo.Size())/1024/1024))
		
		// For PDF files, add content summary
		if strings.HasSuffix(strings.ToLower(filePath), ".pdf") {
			content, err := extractPDFContent(filePath)
			if err == nil {
				// Get first 500 characters as preview
				preview := content
				if len(preview) > 500 {
					preview = preview[:500] + "..."
				}
				response.WriteString("\nContent Preview:\n")
				response.WriteString(preview)
			}
		}

	case isContent:
		response.WriteString("📄 Content Overview:\n")
		response.WriteString(fmt.Sprintf("- File: %s\n", fileInfo.Name()))
		response.WriteString(fmt.Sprintf("- Type: %s\n", filepath.Ext(filePath)))
		
		// For PDF files, show content
		if strings.HasSuffix(strings.ToLower(filePath), ".pdf") {
			content, err := extractPDFContent(filePath)
			if err == nil {
				response.WriteString("\nContent:\n")
				response.WriteString(content)
			} else {
				response.WriteString(fmt.Sprintf("\nError reading content: %v\n", err))
			}
		} else {
			response.WriteString("- Note: Content preview is only available for PDF files\n")
		}

	case isDetails:
		response.WriteString("ℹ️ File Details:\n")
		response.WriteString(fmt.Sprintf("- Name: %s\n", fileInfo.Name()))
		response.WriteString(fmt.Sprintf("- Size: %d bytes\n", fileInfo.Size()))
		response.WriteString(fmt.Sprintf("- Last Modified: %s\n", fileInfo.ModTime().Format(time.RFC1123)))
		response.WriteString(fmt.Sprintf("- Type: %s\n", filepath.Ext(filePath)))
		response.WriteString(fmt.Sprintf("- Path: %s\n", filePath))

	case isSize:
		response.WriteString("📊 Size Information:\n")
		response.WriteString(fmt.Sprintf("- Bytes: %d\n", fileInfo.Size()))
		response.WriteString(fmt.Sprintf("- Kilobytes: %.2f KB\n", float64(fileInfo.Size())/1024))
		response.WriteString(fmt.Sprintf("- Megabytes: %.2f MB\n", float64(fileInfo.Size())/1024/1024))

	case isType:
		response.WriteString("📋 File Type Information:\n")
		ext := filepath.Ext(filePath)
		response.WriteString(fmt.Sprintf("- Extension: %s\n", ext))
		response.WriteString(fmt.Sprintf("- MIME Type: application/%s\n", strings.TrimPrefix(ext, ".")))
		response.WriteString("- Note: This is a basic type detection. For more accurate results, we need to implement proper MIME type detection\n")

	default:
		response.WriteString("🤔 Command Analysis:\n")
		response.WriteString(fmt.Sprintf("- Command received: %s\n", command))
		response.WriteString("- Available commands:\n")
		response.WriteString("  * 'search [term]' or 'find [term]' - Search for content in PDF\n")
		response.WriteString("  * 'give me notes' or 'summary'\n")
		response.WriteString("  * 'what is in this file' or 'show content'\n")
		response.WriteString("  * 'show details' or 'file information'\n")
		response.WriteString("  * 'what is the size' or 'file size'\n")
		response.WriteString("  * 'what type of file' or 'file format'\n")
	}

	return response.String()
}

// Helper functions
func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func ProcessFile(c *gin.Context) {
	// Log the incoming request
	log.Printf("Received process request")

	// Get the file from the request
	file, err := c.FormFile("file")
	command := c.PostForm("command")
	if err != nil {
		log.Printf("Error getting file: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Error getting file: %v", err),
		})
		return
	}

	// Get the command from form data
	// if command == "" {
	// 	c.JSON(http.StatusBadRequest, gin.H{
	// 		"error": "Command is required",
	// 	})
	// 	return
	// }

	// Log file details
	log.Printf("Received file: %s, size: %d", file.Filename, file.Size)

	// Validate file type
	ext := filepath.Ext(file.Filename)
	if ext != ".pdf" && ext != ".jpg" && ext != ".jpeg" && ext != ".png" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid file type. Only PDF and images are allowed",
		})
		return
	}

	// Save file
	filename := filepath.Join(uploadDir, file.Filename)
	if err := c.SaveUploadedFile(file, filename); err != nil {
		log.Printf("Error saving file: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": fmt.Sprintf("Failed to save file: %v", err),
		})
		return
	}

	// Get file info
	fileInfo, err := os.Stat(filename)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": fmt.Sprintf("Error getting file info: %v", err),
		})
		return
	}

	// Process the command
	response := processCommand(command, fileInfo, filename)
	
	c.JSON(http.StatusOK, gin.H{
		"message":  "File processed successfully",
		"file":     file.Filename,
		"statusCode": http.StatusOK,
		"response": response,
	})
} 