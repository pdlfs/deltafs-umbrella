# Script to produce VPIC plots
require(data.table)

# varX and varY are strings (column names in dt)
plot_pair <- function(dt, varX, varY, xs = NaN, xl = NaN, ys = NaN, yl = NaN)
{
    # Plot the canvas
    dtx <- eval(parse(text=paste0("dt$",varX)))
    dty <- eval(parse(text=paste0("dt$",varY)))
    if (is.nan(xs) || is.nan(xl)) {
        xs <- min(dtx)
        xl <- max(dtx)
    }
    if (is.nan(ys) || is.nan(yl)) {
        ys <- min(dty)
        yl <- max(dty)
    }
    
    pdf(file=paste0("./vpic-", varX, "-by-", varY, ".pdf"),
        width=8, height=4, pointsize=10)
    par(mar=c(3, 3.5, .5, .5))
    plot(NULL, xlim = c(xs, xl), ylim = c(ys, yl), xlab = "", ylab = "",
         lwd=2.0, log="x") #axes = 'F'

    #axis(1, las = 1, at = seq(xs, xl, by = (xl-xs)/10), cex.axis = .7)
    #axis(2, las = 1, at = seq(ys, yl, by = (yl-ys)/10), cex.axis = .7)
    mtext(text = varX, side = 1, line = 2)
    mtext(text = varY, side = 2, line = 2)
    #abline(v = seq(xs, xl, by = (xl-xs)/10), col = "gray40", lty = 3, lwd = 0.8)
    abline(h = seq(ys, yl, by = (yl-ys)/10), col = "gray40", lty = 3, lwd = 0.8)

    points(x = dtx, y = dty, type = "o", lty = "solid", lwd = 1.5,
           col = "dodgerblue2", pch = 4)

    dev.off()
}

# varX, varY, varZ are strings (column names in dt)
plot_triple <- function(dt, varX, varY, varZ,
                        xs = NaN, xl = NaN, ys = NaN, yl = NaN, zs = NaN, zl = NaN)
{
    # Plot the canvas
    dtx <- eval(parse(text=paste0("dt$",varX)))
    dty <- eval(parse(text=paste0("dt$",varY)))
    dtz <- eval(parse(text=paste0("dt$",varZ)))
    if (is.nan(xs) || is.nan(xl)) {
        xs <- min(dtx)
        xl <- max(dtx)
    }
    if (is.nan(ys) || is.nan(yl)) {
        ys <- min(dty)
        yl <- max(dty)
    }
    if (is.nan(zs) || is.nan(zl)) {
        zs <- min(dtz)
        zl <- max(dtz)
    }
    
    pdf(file=paste0("./vpic-", varX, "-by-", varY, "-and-", varZ, ".pdf"),
        width=8, height=4, pointsize=10)
    par(mar=c(3, 3.5, .5, .5))
    plot(NULL, xlim = c(xs, xl), ylim = c(ys, yl), xlab = "", ylab = "",
         lwd=2.0, log="x") #axes = 'F'
    
    #axis(1, las = 1, at = seq(xs, xl, by = (xl-xs)/10), cex.axis = .7)
    #axis(2, las = 1, at = seq(ys, yl, by = (yl-ys)/10), cex.axis = .7)
    mtext(text = varX, side = 1, line = 2)
    #mtext(text = varY, side = 2, line = 2)
    #abline(v = seq(xs, xl, by = (xl-xs)/10), col = "gray40", lty = 3, lwd = 0.8)
    abline(h = seq(ys, yl, by = (yl-ys)/10), col = "gray40", lty = 3, lwd = 0.8)
    
    points(x = dtx, y = dty, type = "o", lty = "solid", lwd = 1.5,
           col = "dodgerblue2", pch = 4)
    points(x = dtx, y = dtz, type = "o", lty = "solid", lwd = 1.5,
           col = "springgreen4", pch = 8)
    
    legend("topleft", c(varY, varZ), cex=0.75,
           col=c("dodgerblue2", "springgreen4"),
           lty=c("solid"), lwd=c(1.5), bg = c("white"), #bty="n",
           pch = c(4,8))
    dev.off()
}

# Load data (log data after it has been processed by process_logs.sh)
load_vpic_data <- function(file)
{
  dt <- data.table(read.csv(file))
  dt <- dt[order(particles)]
  dt <- dt[, c("particles_per_process") := particles/processes]
  dt <- dt[, c("pcent_mem_free") := memfree]
  dt <- dt[, c("log_size_gb") := logsize/(2^30)]
  return(dt)
}

dt <- load_vpic_data("./vpic32.csv")
plot_pair(dt,"particles_per_process","pcent_mem_free", ys=0, yl=100)
plot_pair(dt,"particles_per_process","log_size_gb", ys=0, yl=150)
plot_triple(dt,"particles_per_process","simtime","IOtime", ys=0, yl=5200)
