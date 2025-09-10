'use client'

import { useOfflineSync } from '@/lib/hooks/useOfflineSync'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Wifi, WifiOff, RefreshCw, Clock, AlertCircle } from 'lucide-react'

export function OfflineStatus() {
  const { isOnline, pendingActions, syncStatus, syncPendingActions } = useOfflineSync()

  if (isOnline && pendingActions.length === 0) {
    return null
  }

  return (
    <div className="fixed bottom-4 right-4 z-50">
      <Card className="w-80 shadow-lg">
        <CardHeader className="pb-2">
          <CardTitle className="flex items-center text-sm">
            {isOnline ? (
              <>
                <Wifi className="w-4 h-4 mr-2 text-green-600" />
                Online
              </>
            ) : (
              <>
                <WifiOff className="w-4 h-4 mr-2 text-red-600" />
                Offline Mode
              </>
            )}
            
            {syncStatus === 'syncing' && (
              <div className="ml-auto flex items-center">
                <RefreshCw className="w-4 h-4 animate-spin mr-1" />
                <span className="text-xs">Syncing...</span>
              </div>
            )}
          </CardTitle>
        </CardHeader>
        
        <CardContent className="pt-0">
          {!isOnline && (
            <div className="mb-3 p-2 bg-yellow-50 border border-yellow-200 rounded text-xs text-yellow-800">
              <AlertCircle className="w-3 h-3 inline mr-1" />
              You're offline. Your data will sync when you reconnect.
            </div>
          )}
          
          {pendingActions.length > 0 && (
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">
                  Pending Changes
                </span>
                <Badge variant="outline" className="text-xs">
                  {pendingActions.length}
                </Badge>
              </div>
              
              <div className="space-y-1">
                {pendingActions.slice(0, 3).map((action) => (
                  <div key={action.id} className="flex items-center text-xs text-gray-600">
                    <Clock className="w-3 h-3 mr-2" />
                    <span className="flex-1">
                      {action.type === 'LOG_ENTRY' && 'Log entry'}
                      {action.type === 'ACTION_PLAN' && 'Action plan'}
                      {action.type === 'PROFILE_UPDATE' && 'Profile update'}
                    </span>
                    {action.retryCount > 0 && (
                      <span className="text-red-500">
                        (retry {action.retryCount})
                      </span>
                    )}
                  </div>
                ))}
                
                {pendingActions.length > 3 && (
                  <div className="text-xs text-gray-500">
                    +{pendingActions.length - 3} more...
                  </div>
                )}
              </div>
              
              {isOnline && (
                <Button 
                  size="sm" 
                  className="w-full mt-2"
                  onClick={syncPendingActions}
                  disabled={syncStatus === 'syncing'}
                >
                  {syncStatus === 'syncing' ? (
                    <>
                      <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                      Syncing...
                    </>
                  ) : (
                    <>
                      <RefreshCw className="w-4 h-4 mr-2" />
                      Sync Now
                    </>
                  )}
                </Button>
              )}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}