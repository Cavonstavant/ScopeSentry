// Package system -----------------------------
// @file      : system.go
// @author    : Autumn
// @contact   : rainy-autumn@outlook.com
// @time      : 2025/5/2 23:01
// -------------------------------------------
package system

import (
	"github.com/Autumn-27/ScopeSentry/internal/api/response"
	"github.com/Autumn-27/ScopeSentry/internal/constants"
	"github.com/Autumn-27/ScopeSentry/internal/database/redis"
	"github.com/gin-gonic/gin"
)

type VersionResponse struct {
	Code int `json:"code"`
	Data struct {
		List []VersionInfo `json:"list"`
	} `json:"data"`
}

type VersionInfo struct {
	Name     string `json:"name"`
	CVersion string `json:"cversion"`
	LVersion string `json:"lversion"`
	Msg      string `json:"msg"`
}

// GetSystemVersion @Summary      获取系统及节点版本信息
// @Description  获取 ScopeSentry 服务端及所有节点的当前版本信息
// @Tags         System
// @Accept       json
// @Produce      json
// @Success      200  {object}  response.SuccessResponse{data=VersionListResponse}
// @Failure      400  {object}  response.BadRequestResponse
// @Failure      401  {object}  response.UnauthorizedResponse
// @Failure      404  {object}  response.NotFoundResponse
// @Failure      500  {object}  response.InternalServerErrorResponse
// @Router       /system/version [get]
func GetSystemVersion(c *gin.Context) {
	resultList := []VersionInfo{
		{
			Name:     "ScopeSentry-Server",
			CVersion: constants.Version,
			LVersion: "",
			Msg:      "",
		},
	}

	ctx := c.Request.Context()
	keys, err := redis.Client.Keys(ctx, "node:*").Result()
	if err != nil {
		response.InternalServerError(c, "api.system.version.redis_error", err)
		return
	}
	for _, key := range keys {
		name := key[5:]
		hashData, err := redis.Client.HGetAll(ctx, key).Result()
		if err != nil {
			response.InternalServerError(c, "api.system.version.redis_hash_error", err)
			return
		}
		resultList = append(resultList, VersionInfo{
			Name:     name,
			CVersion: hashData["version"],
			LVersion: "",
			Msg:      "",
		})
	}

	response.Success(c, VersionListResponse{
		List: resultList,
	}, "api.system.version.success")
}

// VersionListResponse 版本列表响应结构
// 用于统一响应格式
// @Description 版本信息列表
// @Author Autumn
// @Date 2025-05-02
// @Contact rainy-autumn@outlook.com
type VersionListResponse struct {
	List []VersionInfo `json:"list"`
}
