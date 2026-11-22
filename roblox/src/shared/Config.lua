local C = {}
C.AdminUserIds = {} -- הוסיפו כאן UserId של אדמינים (הבעלים מזוהה אוטומטית)
C.GamePlaceId = 0   -- PlaceId של מקום המשחק (ל-ReservedServer)
C.ServerSizes = { 2, 4, 6, 8 }
C.Grades = {
	Party = { Tint = Color3.fromRGB(235, 220, 255), Sat = 0.15, Contrast = 0.1, Clock = 0.5 },
	Dawn = { Tint = Color3.fromRGB(255, 225, 200), Sat = -0.3, Contrast = 0.22, Clock = 6.4 },
}
return C
