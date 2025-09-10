'use client'

import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, Cell } from 'recharts'
import { format, subDays, startOfDay } from 'date-fns'

interface SymptomData {
  date: string
  wheezing: number
  coughing: number
  chestTightness: number
  shortnessOfBreath: number
  overall: number
}

interface SymptomChartProps {
  data: SymptomData[]
}

// Generate mock data for demo
const generateMockData = (days: number = 7): SymptomData[] => {
  const data: SymptomData[] = []
  
  for (let i = days - 1; i >= 0; i--) {
    const date = startOfDay(subDays(new Date(), i))
    const wheezing = Math.floor(Math.random() * 6)
    const coughing = Math.floor(Math.random() * 6)
    const chestTightness = Math.floor(Math.random() * 5)
    const shortnessOfBreath = Math.floor(Math.random() * 4)
    const overall = Math.round((wheezing + coughing + chestTightness + shortnessOfBreath) / 4)
    
    data.push({
      date: format(date, 'MMM dd'),
      wheezing,
      coughing,
      chestTightness,
      shortnessOfBreath,
      overall
    })
  }
  
  return data
}

export function SymptomChart({ data }: SymptomChartProps) {
  const chartData = data.length > 0 ? data : generateMockData()
  
  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload
      
      return (
        <div className="bg-white border border-gray-200 rounded-lg p-3 shadow-lg">
          <p className="font-medium mb-2">{label}</p>
          <div className="space-y-1">
            <div className="flex items-center">
              <div className="w-3 h-3 bg-blue-500 rounded-full mr-2"></div>
              <span className="text-sm">Wheezing: {data.wheezing}/10</span>
            </div>
            <div className="flex items-center">
              <div className="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
              <span className="text-sm">Coughing: {data.coughing}/10</span>
            </div>
            <div className="flex items-center">
              <div className="w-3 h-3 bg-yellow-500 rounded-full mr-2"></div>
              <span className="text-sm">Chest Tightness: {data.chestTightness}/10</span>
            </div>
            <div className="flex items-center">
              <div className="w-3 h-3 bg-red-500 rounded-full mr-2"></div>
              <span className="text-sm">Shortness of Breath: {data.shortnessOfBreath}/10</span>
            </div>
            <div className="flex items-center font-medium pt-1 border-t">
              <div className="w-3 h-3 bg-purple-500 rounded-full mr-2"></div>
              <span className="text-sm">Overall: {data.overall}/10</span>
            </div>
          </div>
        </div>
      )
    }
    return null
  }

  const getBarColor = (value: number) => {
    if (value <= 2) return '#22c55e' // green
    if (value <= 4) return '#eab308' // yellow
    if (value <= 6) return '#f97316' // orange
    return '#ef4444' // red
  }

  return (
    <div className="w-full h-64 sm:h-80">
      <ResponsiveContainer width="100%" height="100%">
        <BarChart
          data={chartData}
          margin={{
            top: 20,
            right: 30,
            left: 20,
            bottom: 20,
          }}
        >
          <CartesianGrid strokeDasharray="3 3" className="opacity-30" />
          <XAxis 
            dataKey="date" 
            axisLine={false}
            tickLine={false}
            tick={{ fontSize: 12 }}
          />
          <YAxis 
            axisLine={false}
            tickLine={false}
            tick={{ fontSize: 12 }}
            domain={[0, 10]}
          />
          <Tooltip content={<CustomTooltip />} />
          
          <Bar 
            dataKey="overall" 
            name="Overall Severity"
            radius={[4, 4, 0, 0]}
          >
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={getBarColor(entry.overall)} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
      
      {/* Legend */}
      <div className="mt-4 flex justify-center">
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 text-xs">
          <div className="flex items-center">
            <div className="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
            <span>0-2 Mild</span>
          </div>
          <div className="flex items-center">
            <div className="w-3 h-3 bg-yellow-500 rounded-full mr-2"></div>
            <span>3-4 Moderate</span>
          </div>
          <div className="flex items-center">
            <div className="w-3 h-3 bg-orange-500 rounded-full mr-2"></div>
            <span>5-6 Severe</span>
          </div>
          <div className="flex items-center">
            <div className="w-3 h-3 bg-red-500 rounded-full mr-2"></div>
            <span>7+ Very Severe</span>
          </div>
        </div>
      </div>
    </div>
  )
}