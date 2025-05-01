package routes

import (
	"github.com/gin-gonic/gin"
	"doc-processor-server/handlers"
)

func InitializeRoutes(router *gin.Engine) {
	// API routes
	api := router.Group("/api")
	{
		api.POST("/process", handlers.ProcessFile)
		api.POST("/login", handlers.Login)
	}
} 